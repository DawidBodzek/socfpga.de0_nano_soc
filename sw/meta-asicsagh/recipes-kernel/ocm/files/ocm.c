// SPDX-License-Identifier: GPL-2.0
/**
 * Copyright 2023 Pawel Skrzypiec <pawel.skrzypiec@agh.edu.pl>
 */

#include <linux/dma-mapping.h>
#include <linux/fs.h>
#include <linux/miscdevice.h>
#include <linux/mm.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/platform_device.h>

#define OCM_GET_SIZE            _IOR('o', 0, u32)       /* 2147774208 */
#define OCM_GET_BUF_PHYS_ADDR   _IOR('o', 1, u32)       /* 2147774209 */

struct buf {
        void *vaddr;
        phys_addr_t phys_addr;
};

struct ocm {
        struct platform_device *pdev;
        struct miscdevice mdev;
        u32 addr;
        u32 size;
        struct buf buf;
};

static ssize_t ocm_read(struct file *filp, char __user *buf,
        size_t count, loff_t *f_pos)
{
        struct ocm *ocm = container_of(filp->private_data, struct ocm, mdev);

        if (count > ocm->size) {
                count = ocm->size;
                dev_warn(&ocm->pdev->dev,
                        "count (%d) truncated to %d\n", count, ocm->size);
        }

        copy_to_user(buf, ocm->buf.vaddr, count);
        return count;
}

static ssize_t ocm_write(struct file *filp, const char __user *buf,
        size_t count, loff_t *f_pos)
{
        struct ocm *ocm = container_of(filp->private_data, struct ocm, mdev);

        if (count > ocm->size) {
                count = ocm->size;
                dev_warn(&ocm->pdev->dev,
                        "count (%d) truncated to %d\n", count, ocm->size);
        }

        copy_from_user(ocm->buf.vaddr, buf, count);
        return count;
}

static long ocm_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
        struct ocm *ocm = container_of(filp->private_data, struct ocm, mdev);
        int ret;

        switch (cmd) {
        case OCM_GET_SIZE:
                ret = ocm->size;
                break;
        case OCM_GET_BUF_PHYS_ADDR:
                ret = ocm->buf.phys_addr;
                break;
        default:
                ret = -ENOTTY;
                break;
        }

        return ret;
}

static int ocm_mmap(struct file *filp, struct vm_area_struct *vma)
{
        struct ocm *ocm = container_of(filp->private_data,
                struct ocm, mdev);

        if (vma->vm_end - vma->vm_start != ocm->size)
                return -EINVAL;

        vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);
        vma->vm_pgoff = ocm->addr >> PAGE_SHIFT;

        return remap_pfn_range(vma, vma->vm_start, vma->vm_pgoff,
                ocm->size, vma->vm_page_prot);
}

static const struct file_operations ocm_fops = {
        .owner = THIS_MODULE,
        .read = ocm_read,
        .write = ocm_write,
        .unlocked_ioctl = ocm_ioctl,
        .mmap = ocm_mmap
};

static int ocm_probe(struct platform_device *pdev)
{
        int err;
        struct ocm *ocm;
        struct resource *res;

        ocm = devm_kzalloc(&pdev->dev, sizeof(struct ocm), GFP_KERNEL);
        if (!ocm) {
                dev_err(&pdev->dev, "failed to allocate struct ocm\n");
                err = -ENOMEM;
                goto out_ret_err;
        }

        ocm->pdev = pdev;
        platform_set_drvdata(pdev, ocm);

        res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
        if (!res) {
                dev_err(&pdev->dev, "failed to get resource\n");
                err = -EINVAL;
                goto out_ret_err;
        }

        ocm->addr = res->start;
        ocm->size = resource_size(res);

        ocm->buf.vaddr = dmam_alloc_coherent(&pdev->dev, ocm->size,
                &ocm->buf.phys_addr, GFP_KERNEL);
        if (!ocm->buf.vaddr) {
                dev_err(&pdev->dev, "buf allocation failed\n");
                goto out_ret_err;
        }

        ocm->mdev.minor = MISC_DYNAMIC_MINOR;
        ocm->mdev.name = "ocm";
        ocm->mdev.fops = &ocm_fops;

        err = misc_register(&ocm->mdev);
        if (err) {
                dev_err(&pdev->dev, "failed to register miscdevice\n");
                return err;
        }

        dev_info(&pdev->dev, "probed\n");
        return 0;

out_ret_err:
        return err;
}

static int ocm_remove(struct platform_device *pdev)
{
        struct ocm *ocm = platform_get_drvdata(pdev);

        misc_deregister(&ocm->mdev);
        dev_info(&pdev->dev, "removed\n");
        return 0;
}

static const struct of_device_id ocm_ids[] = {
        { .compatible = "agh,ocm" },
        { }
};

MODULE_DEVICE_TABLE(of, ocm_ids);

static struct platform_driver ocm_driver = {
    .probe = ocm_probe,
    .remove = ocm_remove,
    .driver = {
        .name = "ocm",
        .owner = THIS_MODULE,
        .of_match_table = ocm_ids
    }
};

module_platform_driver(ocm_driver);

MODULE_AUTHOR("Pawel Skrzypiec <pawel.skrzypiec@agh.edu.pl>");
MODULE_DESCRIPTION("OCM driver");
MODULE_VERSION("1.0");
MODULE_LICENSE("GPL v2");
