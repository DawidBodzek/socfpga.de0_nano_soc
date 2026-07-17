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
#include <linux/atomic.h>
#include <linux/wait.h>
#include <linux/platform_device.h>

struct test {
    struct platform_device *pdev;
    struct miscdevice mdev;
    void __iomem *addr;

    wait_queue_head_t wait;
    atomic_t ready;
};

static irqreturn_t test_handler(int irq, void *dev_id)
{
    struct test *test = (struct test *)dev_id;

    atomic_set(&test->ready, 1);
    wake_up_interruptible(&test->wait);

    pr_info("FPGA IRQ\n");
    return IRQ_HANDLED;
}

static ssize_t test_read(struct file *filp, char __user *buf,
    size_t count, loff_t *f_pos)
{
    struct test *test = container_of(filp->private_data, struct test, mdev);
    
    atomic_set(&test->ready, 0);
    iowrite32(1, test->addr);

    if (wait_event_interruptible(test->wait, atomic_read(&test->ready))) {
	return -ERESTARTSYS;
    }

    pr_info("Ready asserted\n");
    return 0;
}

static const struct file_operations test_fops = {
    .owner = THIS_MODULE,
    .read = test_read
};

static int test_probe(struct platform_device *pdev)
{
    int err;
    int irq;
    struct test *test;
    struct resource *res;

    test = devm_kzalloc(&pdev->dev, sizeof(struct test), GFP_KERNEL);
    if (!test) {
        dev_err(&pdev->dev, "failed to allocate struct test\n");
        err = -ENOMEM;
        return err;
    }

    test->pdev = pdev;
    platform_set_drvdata(pdev, test);

    res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    if (!res) {
	dev_err(&pdev->dev, "failed to get resource\n");
	err = -EINVAL;
	return err;
    }

    test->addr = devm_ioremap_resource(&pdev->dev, res);

    test->mdev.minor = MISC_DYNAMIC_MINOR;
    test->mdev.name = "test";
    test->mdev.fops = &test_fops;

    err = misc_register(&test->mdev);
    if (err) {
        dev_err(&pdev->dev, "failed to register miscdevice\n");
        return err;
    }

    irq = platform_get_irq(pdev, 0);

    err = devm_request_irq(&pdev->dev, irq, test_handler, 0, "test_irq", test);
    if (err) {
	dev_err(&pdev->dev, "failed to request irq\n");
	return err;
    }

    init_waitqueue_head(&test->wait);
    atomic_set(&test->ready, 0);

    dev_info(&pdev->dev, "probed\n");
    return 0;
}

static int test_remove(struct platform_device *pdev)
{
    struct test *test = platform_get_drvdata(pdev);

    misc_deregister(&test->mdev);
    dev_info(&pdev->dev, "removed\n");
    return 0;
}

static const struct of_device_id test_ids[] = {
    { .compatible = "my_test"},
    { }
};

MODULE_DEVICE_TABLE(of, test_ids);

static struct platform_driver test_driver = {
    .probe = test_probe,
    .remove = test_remove,
    .driver = {
        .name = "test_driver",
        .owner = THIS_MODULE,
        .of_match_table = test_ids
    }
};

module_platform_driver(test_driver);

MODULE_DESCRIPTION("simple irq driver for testing");
MODULE_AUTHOR("Dawid Bodzek <dbodzek@student.agh.edu.pl>");
MODULE_VERSION("1.0");
MODULE_LICENSE("GPL v2");
