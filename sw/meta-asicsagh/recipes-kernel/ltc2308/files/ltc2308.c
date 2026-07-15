// SPDX-License-Identifier: GPL-2.0
/**
 * Copyright 2026 Dawid Bodzek <dbodzek@student.agh.edu.pl>
 */

#include <linux/dma-mapping.h>
#include <linux/fs.h>
#include <linux/miscdevice.h>
#include <linux/mm.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/platform_device.h>

struct ltc2308 {
    struct platform_device *pdev;
    struct miscdevice mdev;
};

static ssize_t ltc2308_read(struct file *filp, char __user *buf,
        size_t count, loff_t *f_pos) 
{
    struct ltc2308 *ltc2308 = container_of(filp->private_data, struct ltc2308, mdev);

    const char *msg = "Hello\n";

    copy_to_user(buf, msg, count);
    return count;
}

static const struct file_operations ltc2308_fops = {
    .owner = THIS_MODULE,
    .read = ltc2308_read
};

static int ltc2308_probe(struct platform_device *pdev)
{
    int err;
    struct ltc2308 *ltc2308;

    ltc2308 = devm_kzalloc(&pdev->dev, sizeof(struct ltc2308), GFP_KERNEL);
    if (!ltc2308) {
        dev_err(&pdev->dev, "failed to allocate struct ltc2308\n");
        err = -ENOMEM;
        return err;
    }

    ltc2308->pdev = pdev;
    platform_set_drvdata(pdev, ltc2308);

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
        .name = "ltc2308",
        .owner = THIS_MODULE,
        .of_match_table = ltc2308_ids
    }
};

module_platform_driver(ltc2308_driver);

MODULE_DESCRIPTION("ltc2308 driver");
MODULE_AUTHOR("Dawid Bodzek <dbodzek@student.agh.edu.pl>");
MODULE_VERSION("1.0");
MODULE_LICENSE("GPL v2");
