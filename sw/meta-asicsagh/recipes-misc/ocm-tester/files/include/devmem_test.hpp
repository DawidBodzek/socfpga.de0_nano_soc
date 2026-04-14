#pragma once

#include <gtest/gtest.h>

class Devmem_test : public testing::Test {
public:
    static void SetUpTestSuite();
    static void TearDownTestSuite();

    void SetUp() override;

protected:
    static constexpr uint32_t ocm_size{0x1'0000};
    
    inline static int fd{-1};
    inline static volatile uint32_t *mem{};

    std::array<uint32_t, ocm_size / sizeof(uint32_t)> wdata;
    std::array<uint32_t, ocm_size / sizeof(uint32_t)> rdata;
    
    static void print_bandwidth(std::string_view operation, 
        const auto &start_time, const auto &stop_time);
};
