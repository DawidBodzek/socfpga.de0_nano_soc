#include <driver_test.hpp>

#include <cstring>
#include <format>
#include <fcntl.h>
#include <unistd.h>
#include <experimental/random>
#include <sys/ioctl.h>
#include <sys/mman.h>

static constexpr uint32_t ocm_get_size          {2147774208};
static constexpr uint32_t ocm_get_buf_phys_addr {2147774209};

void Driver_test::SetUpTestSuite()
{
    fd = open("/dev/ocm", O_RDWR | O_SYNC);
    ASSERT_GE(fd, 0);

    const auto size = ioctl(fd, ocm_get_size);
    ASSERT_GE(size, 0);
    ocm_size = size;

    mem = reinterpret_cast<volatile uint32_t *>(mmap(NULL, ocm_size, PROT_WRITE, MAP_SHARED, fd, 0));
    ASSERT_NE(mem, MAP_FAILED);

    const auto addr = ioctl(fd, ocm_get_buf_phys_addr);
    ASSERT_GE(addr, 0);
    buf_phys_addr = addr;

    devmem_fd = open("/dev/mem", O_RDWR | O_SYNC);
    ASSERT_GE(devmem_fd, 0);

    buf = reinterpret_cast<volatile uint32_t *>(mmap(NULL, ocm_size, PROT_WRITE, MAP_SHARED, devmem_fd, buf_phys_addr));
    ASSERT_NE(buf, MAP_FAILED);

    wdata.resize(ocm_size / sizeof(uint32_t));
    rdata.resize(ocm_size / sizeof(uint32_t));
}

void Driver_test::TearDownTestSuite()
{
    munmap(const_cast<uint32_t *>(buf), ocm_size);
    close(devmem_fd);

    munmap(const_cast<uint32_t *>(mem), ocm_size);
    close(fd);
}

void Driver_test::SetUp()
{
    std::generate(begin(wdata), end(wdata), []() {
        return std::experimental::randint<uint32_t>(0, std::numeric_limits<uint32_t>::max());
    });
}

void Driver_test::print_bandwidth(std::string_view operation,
    const auto &start_time, const auto &stop_time)
{
    const auto duration = std::chrono::duration_cast<std::chrono::nanoseconds>(stop_time - start_time);
    const auto bandwidth = ocm_size / (duration.count() * 1e-9) / 1'000'000.0;

    std::cout << std::format("{} bandwidth: {:.5f} [MB/s]", operation, bandwidth) << std::endl;
}

TEST_F(Driver_test, direct_write_read)
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

TEST_F(Driver_test, memcpy_write_read)
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

TEST_F(Driver_test, buf_driver_write_devmem_read)
{
    const auto write_start = std::chrono::high_resolution_clock::now();
    ASSERT_EQ(write(fd, wdata.data(), ocm_size), ocm_size);
    const auto write_stop = std::chrono::high_resolution_clock::now();

    const auto read_start = std::chrono::high_resolution_clock::now();
    std::memcpy(rdata.data(), const_cast<uint32_t *>(buf), ocm_size);
    const auto read_stop = std::chrono::high_resolution_clock::now();

    ASSERT_EQ(rdata, wdata);

    print_bandwidth("write", write_start, write_stop);
    print_bandwidth("read", read_start, read_stop);
}

TEST_F(Driver_test, buf_devmem_write_driver_read)
{
    const auto write_start = std::chrono::high_resolution_clock::now();
    std::memcpy(const_cast<uint32_t *>(buf), wdata.data(), ocm_size);
    const auto write_stop = std::chrono::high_resolution_clock::now();

    const auto read_start = std::chrono::high_resolution_clock::now();
    ASSERT_EQ(read(fd, rdata.data(), ocm_size), ocm_size);
    const auto read_stop = std::chrono::high_resolution_clock::now();

    ASSERT_EQ(rdata, wdata);

    print_bandwidth("write", write_start, write_stop);
    print_bandwidth("read", read_start, read_stop);
}

TEST_F(Driver_test, buf_driver_write_driver_read)
{
    const auto write_start = std::chrono::high_resolution_clock::now();
    ASSERT_EQ(write(fd, wdata.data(), ocm_size), ocm_size);
    const auto write_stop = std::chrono::high_resolution_clock::now();

    const auto read_start = std::chrono::high_resolution_clock::now();
    ASSERT_EQ(read(fd, rdata.data(), ocm_size), ocm_size);
    const auto read_stop = std::chrono::high_resolution_clock::now();

    ASSERT_EQ(rdata, wdata);

    print_bandwidth("write", write_start, write_stop);
    print_bandwidth("read", read_start, read_stop);
}
