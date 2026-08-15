// SPDX-License-Identifier: GPL-2.0
/**
 * Copyright 2026 Dawid Bodzek <dbodzek@student.agh.edu.pl>
 */

#include <linux/fs.h>
#include <linux/miscdevice.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/interrupt.h>
#include <linux/atomic.h>
#include <linux/wait.h>
#include <linux/platform_device.h>
#include <linux/bitops.h>
#include <linux/bitfield.h>

/* CSR */

#define LTC_DATA_REG     0x0C
#define LTC_CFG_REG      0x08

/* Bit masks */

#define SIGNAL_MODE_MASK BIT(5)
#define SIGN_MASK        BIT(4)
#define CHANNEL_MASK     GENMASK(3, 2)
#define POLARITY_MASK    BIT(1)

struct spi_data {
        u8 tx_data;
        u16 rx_data;
};

struct ltc2308 {
        struct platform_device *pdev;
        struct miscdevice mdev;
        struct spi_data spi_data;
        void __iomem *addr;
        wait_queue_head_t waitq;
        atomic_t ready;
        atomic_t new_cfg;
};

static irqreturn_t ltc2308_irq_handler(int irq, void *dev_id)
{
        struct ltc2308 *ltc2308 = (struct ltc2308 *)dev_id;

        ltc2308->spi_data.rx_data = ioread16(ltc2308->addr + LTC_DATA_REG);

        atomic_set(&ltc2308->ready, 1);
        wake_up_interruptible(&ltc2308->waitq);

        return IRQ_HANDLED;
}

static int ltc2308_conversion(struct ltc2308 *ltc2308)
{
        atomic_set(&ltc2308->ready, 0);

        iowrite8(1, ltc2308->addr);
        if (wait_event_interruptible(ltc2308->waitq, atomic_read(&ltc2308->ready))) {
                return -ERESTARTSYS;
        }

        return 0;
}

static ssize_t ltc2308_read(struct file *filp, char __user *buf,
        size_t count, loff_t *f_pos)
{
        struct ltc2308 *ltc2308 = container_of(filp->private_data, struct ltc2308, mdev);
        char data_buf[16];
        int len, ret;

        if (*f_pos > 0) {
                return 0;       /* EOF */
        }

        /* Configure MUX and operations modes for new conversion */
        if (atomic_read(&ltc2308->new_cfg)) {
                iowrite8(ltc2308->spi_data.tx_data, ltc2308->addr + LTC_CFG_REG);
                atomic_set(&ltc2308->new_cfg, 0);
                ret = ltc2308_conversion(ltc2308);
                if (ret < 0) {
                        return ret;
                }
        }

        ret = ltc2308_conversion(ltc2308);
        if (ret < 0) {
                return ret;
        }

        len = scnprintf(data_buf, sizeof(data_buf), "%X\n", ltc2308->spi_data.rx_data);
        if (copy_to_user(buf, data_buf, len)) {
                return -EFAULT;
        }

        *f_pos = *f_pos + len;
        return len;
}

static const struct file_operations ltc2308_fops = {
        .owner = THIS_MODULE,
        .read = ltc2308_read
};

static int ltc2308_set_bits(struct ltc2308 *ltc2308, const char *buf, u8 mask)
{
        u8 value;
        int ret;

        ret = kstrtou8(buf, 0, &value);
        if (ret < 0) {
                return ret;
        }

        ltc2308->spi_data.tx_data &= ~mask;
        ltc2308->spi_data.tx_data |= FIELD_PREP(mask, value);

        atomic_set(&ltc2308->new_cfg, 1);
        return 0;
}

static ssize_t signal_mode_store(struct device *dev, struct device_attribute *attr,
        const char *buf, size_t count)
{
        struct ltc2308 *ltc2308 = dev_get_drvdata(dev);
        int ret;

        ret = ltc2308_set_bits(ltc2308, buf, SIGNAL_MODE_MASK);
        if (ret < 0) {
                return ret;
        }

        return count;
}

static ssize_t sign_store(struct device *dev, struct device_attribute *attr, 
        const char *buf, size_t count)
{
        struct ltc2308 *ltc2308 = dev_get_drvdata(dev);
        int ret;

        ret = ltc2308_set_bits(ltc2308, buf, SIGN_MASK);
        if (ret < 0) {
                return ret;
        }

        return count;
}

static ssize_t channel_store(struct device *dev, struct device_attribute *attr, 
        const char *buf, size_t count)
{
        struct ltc2308 *ltc2308 = dev_get_drvdata(dev);
        int ret;

        ret = ltc2308_set_bits(ltc2308, buf, CHANNEL_MASK);
        if (ret < 0) {
                return ret;
        }

        return count;
}

static ssize_t polarity_store(struct device *dev, struct device_attribute *attr, 
        const char *buf, size_t count)
{
        struct ltc2308 *ltc2308 = dev_get_drvdata(dev);
        int ret;

        ret = ltc2308_set_bits(ltc2308, buf, POLARITY_MASK);
        if (ret < 0) {
                return ret;
        }

        return count;
}

static DEVICE_ATTR_WO(signal_mode);
static DEVICE_ATTR_WO(sign);
static DEVICE_ATTR_WO(channel);
static DEVICE_ATTR_WO(polarity);

static struct attribute *ltc2308_attrs[] = {
        &dev_attr_signal_mode.attr,
        &dev_attr_sign.attr,
        &dev_attr_channel.attr,
        &dev_attr_polarity.attr,
        NULL,
};

ATTRIBUTE_GROUPS(ltc2308);

static int ltc2308_probe(struct platform_device *pdev)
{
        int err;
        int irq;
        struct ltc2308 *ltc2308;
        struct resource *res;

        ltc2308 = devm_kzalloc(&pdev->dev, sizeof(struct ltc2308), GFP_KERNEL);
        if (!ltc2308) {
                dev_err(&pdev->dev, "failed to allocate struct ltc2308\n");
                err = -ENOMEM;
                return err;
        }

        ltc2308->pdev = pdev;
        platform_set_drvdata(pdev, ltc2308);

        err = devm_device_add_groups(&pdev->dev, ltc2308_groups);
        if (err) {
                dev_err(&pdev->dev, "failed to add group\n");
                return err;
        }

        res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
        if (!res) {
                dev_err(&pdev->dev, "failed to get resource\n");
                err = -EINVAL;
                return err;
        }

        ltc2308->addr = devm_ioremap_resource(&pdev->dev, res);

        init_waitqueue_head(&ltc2308->waitq);
        atomic_set(&ltc2308->ready, 0);
        atomic_set(&ltc2308->new_cfg, 0);

        irq = platform_get_irq(pdev, 0);
        if (irq < 0) {
                dev_err(&pdev->dev, "failed to get irq\n");
                err = irq;
                return err;
        }

        err = devm_request_irq(&pdev->dev, irq, ltc2308_irq_handler, 0, "ltc2308", 
                ltc2308);
        if (err) {
                dev_err(&pdev->dev, "failed to request irq\n");
                return err;
        }

        ltc2308->mdev.minor = MISC_DYNAMIC_MINOR;
        ltc2308->mdev.name = "ltc2308";
        ltc2308->mdev.fops = &ltc2308_fops;

        err = misc_register(&ltc2308->mdev);
        if (err) {
                dev_err(&pdev->dev, "failed to register miscdevice\n");
                return err;
        }

        dev_info(&pdev->dev, "probed\n");
        return 0;
}

static int ltc2308_remove(struct platform_device *pdev)
{
        struct ltc2308 *ltc2308 = platform_get_drvdata(pdev);

        misc_deregister(&ltc2308->mdev);
        dev_info(&pdev->dev, "removed\n");
        return 0;
}

static const struct of_device_id ltc2308_ids[] = {
        { .compatible = "ltc2308"},
        { }
};

MODULE_DEVICE_TABLE(of, ltc2308_ids);

static struct platform_driver ltc2308_driver = {
        .probe = ltc2308_probe,
        .remove = ltc2308_remove,
        .driver = {
            .name = "ltc2308_driver",
            .owner = THIS_MODULE,
            .of_match_table = ltc2308_ids
        }
};

module_platform_driver(ltc2308_driver);

MODULE_DESCRIPTION("ltc2308 driver");
MODULE_AUTHOR("Dawid Bodzek <dbodzek@student.agh.edu.pl>");
MODULE_VERSION("1.0");
MODULE_LICENSE("GPL v2");
