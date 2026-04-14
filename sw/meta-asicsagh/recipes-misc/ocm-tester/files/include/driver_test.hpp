#pragma once

#include <gtest/gtest.h>

class Driver_test : public testing::Test {
public:
    static void SetUpTestSuite();
    static void TearDownTestSuite();

    void SetUp() override;

protected:
    inline static int fd{-1};
    inline static volatile uint32_t *mem{};
    inline static uint32_t ocm_size{};
    inline static uint32_t buf_phys_addr{};

    inline static int devmem_fd{-1};
    inline static volatile uint32_t *buf{};

    inline static std::vector<uint32_t> wdata;
    inline static std::vector<uint32_t> rdata;

    static void print_bandwidth(std::string_view operation, 
        const auto &start_time, const auto &stop_time);
};
