#include <devmem_test.hpp>

#include <chrono>
#include <cstdint>
#include <cstring>
#include <fcntl.h>
#include <unistd.h>
#include <experimental/random>
#include <sys/mman.h>

static constexpr uint32_t h2f_slaves_address    {0xc000'0000};
static constexpr uint32_t h2f_lw_slaves_address {0xff20'0000};
static constexpr uint32_t ocm_offset            {0x0000'0000};

void Devmem_test::SetUpTestSuite()
{
    fd = open("/dev/mem", O_RDWR | O_SYNC);
    ASSERT_GE(fd, 0);

    mem = reinterpret_cast<volatile uint32_t *>(mmap(NULL, ocm_size, PROT_WRITE, MAP_SHARED, fd,
        h2f_slaves_address + ocm_offset));
    ASSERT_NE(mem, MAP_FAILED);
}

void Devmem_test::TearDownTestSuite()
{
    munmap(const_cast<uint32_t *>(mem), ocm_size);
    close(fd);
}

void Devmem_test::SetUp()
{
    std::generate(begin(wdata), end(wdata), []() {
        return std::experimental::randint<uint32_t>(0, std::numeric_limits<uint32_t>::max());
    });
}

void Devmem_test::print_bandwidth(std::string_view operation,
    const auto &start_time, const auto &stop_time)
{
    const auto duration = std::chrono::duration_cast<std::chrono::nanoseconds>(stop_time - start_time);
    const auto bandwidth = ocm_size / (duration.count() * 1e-9) / 1'000'000.0;

    std::cout << std::format("{} bandwidth: {:.5f} [MB/s]", operation, bandwidth) << std::endl;
}

TEST_F(Devmem_test, h2f_direct_write_read)
{
    const auto write_start = std::chrono::high_resolution_clock::now();
    for (size_t i = 0; i < wdata.size(); ++i)
        mem[i] = wdata[i];
    const auto write_stop = std::chrono::high_resolution_clock::now();

    const auto read_start = std::chrono::high_resolution_clock::now();
    for (size_t i = 0; i < rdata.size(); ++i)
        rdata[i] = mem[i];
    const auto read_stop = std::chrono::high_resolution_clock::now();

    ASSERT_EQ(rdata, wdata);

    print_bandwidth("write", write_start, write_stop);
    print_bandwidth("read", read_start, read_stop);
}

TEST_F(Devmem_test, h2f_memcpy_write_read)
{
    const auto write_start = std::chrono::high_resolution_clock::now();
    std::memcpy(const_cast<uint32_t *>(mem), wdata.data(), ocm_size);
    const auto write_stop = std::chrono::high_resolution_clock::now();

    const auto read_start = std::chrono::high_resolution_clock::now();
    std::memcpy(rdata.data(), const_cast<uint32_t *>(mem), ocm_size);
    const auto read_stop = std::chrono::high_resolution_clock::now();

    ASSERT_EQ(rdata, wdata);

    print_bandwidth("write", write_start, write_stop);
    print_bandwidth("read", read_start, read_stop);
}

TEST_F(Devmem_test, h2f_lw_direct_write_read)
{
    const auto write_start = std::chrono::high_resolution_clock::now();
    for (size_t i = 0; i < wdata.size(); ++i)
        mem[i] = wdata[i];
    const auto write_stop = std::chrono::high_resolution_clock::now();

    const auto read_start = std::chrono::high_resolution_clock::now();
    for (size_t i = 0; i < rdata.size(); ++i)
        rdata[i] = mem[i];
    const auto read_stop = std::chrono::high_resolution_clock::now();

    ASSERT_EQ(rdata, wdata);

    print_bandwidth("write", write_start, write_stop);
    print_bandwidth("read", read_start, read_stop);
}

TEST_F(Devmem_test, h2f_lw_memcpy_write_read)
{
    const auto write_start = std::chrono::high_resolution_clock::now();
    std::memcpy(const_cast<uint32_t *>(mem), wdata.data(), ocm_size);
    const auto write_stop = std::chrono::high_resolution_clock::now();

    const auto read_start = std::chrono::high_resolution_clock::now();
    std::memcpy(rdata.data(), const_cast<uint32_t *>(mem), ocm_size);
    const auto read_stop = std::chrono::high_resolution_clock::now();

    ASSERT_EQ(rdata, wdata);

    print_bandwidth("write", write_start, write_stop);
    print_bandwidth("read", read_start, read_stop);
}
