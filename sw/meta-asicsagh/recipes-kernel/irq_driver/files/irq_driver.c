// SPDX-License-Identifier: GPL-2.0
/**
 * Copyright 2026 Dawid Bodzek <dbodzek@student.agh.edu.pl>
 */

#include <linux/fs.h>
#include <linux/miscdevice.h>
#include <linux/mm.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/interrupt.h>
#include <linux/delay.h>
#include <linux/atomic.h>
#include <linux/platform_device.h>

struct irq_driver {
    struct platform_device *pdev;
    struct miscdevice mdev;
    atomic_t ready;
};

static irqreturn_t irq_driver_handler(int irq, void *dev_id)
{
    struct irq_driver *irq_driver = (struct irq_driver *)dev_id;

    atomic_set(&irq_driver->ready, 1);
    pr_info("FPGA IRQ\n");
    return IRQ_HANDLED;
}

static ssize_t irq_driver_read(struct file *filp, char __user *buf,
    size_t count, loff_t *f_pos)
{
    struct irq_driver *irq_driver = container_of(filp->private_data, struct irq_driver, mdev);
    atomic_set(&irq_driver->ready, 0);

    while (!atommic_read(&irq_driver->ready)) {
        msleep(5);
    }

    pr_info("Ready asserted\n");
    return count;
}

static const struct file_operations irq_driver_fops = {
    .owner = THIS_MODULE,
    .read = irq_driver_read
};

static int irq_driver_probe(struct platform_device *pdev)
{
    int err;
    struct irq_driver *irq_driver;

    irq_driver = devm_kzalloc(&pdev->dev, sizeof(struct irq_driver), GFP_KERNEL);
    if (!irq_driver) {
        dev_err(&pdev->dev, "failed to allocate struct irq_driver\n");
        err = -ENOMEM;
        return err;
    }

    irq_driver->pdev = pdev;
    platform_set_drvdata(pdev, irq_driver);

    irq_driver->mdev.minor = MISC_DYNAMIC_MINOR;
    irq_driver->mdev.name = "irq_driver";
    irq_driver->mdev.fops = &irq_driver_fops;

    err = misc_register(&irq_driver->mdev);
    if (err) {
        dev_err(&pdev->dev, "failed to register miscdevice\n");
        return err;
    }

    dev_info(&pdev->dev, "probed\n");
    return 0;
}

static int irq_driver_remove(struct platform_device *pdev)
{
    struct irq_driver *irq_driver = platform_get_drvdata(pdev);

    misc_deregister(&irq_driver->mdev);
    dev_info(&pdev->dev, "removed\n");
    return 0;
}

static const struct of_device_id irq_driver_ids[] = {
    { .compatible = "irq_driver"},
    { }
};

MODULE_DEVICE_TABLE(of, irq_driver_ids);

static struct platform_driver irq_driver_pd = {
    .probe = irq_driver_probe,
    .remove = irq_driver_remove,
    .driver = {
        .name = "irq_driver",
        .owner = THIS_MODULE,
        .of_match_table = irq_driver_ids
    }
};

module_platform_driver(irq_driver_pd);

MODULE_DESCRIPTION("simple irq driver for testing");
MODULE_AUTHOR("Dawid Bodzek <dbodzek@student.agh.edu.pl>");
MODULE_VERSION("1.0");
MODULE_LICENSE("GPL v2");
