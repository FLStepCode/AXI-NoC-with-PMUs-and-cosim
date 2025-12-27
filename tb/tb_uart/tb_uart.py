import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock
from cocotbext.uart import UartSource

@cocotb.test
async def test_uart_rec(dut):
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start())

    source = UartSource(dut.rx_i, baud=100_000_000, bits=8)

    dut.arstn_i.value = 0
    dut.data_ready_i.value = 0
    await RisingEdge(dut.clk_i)
    dut.arstn_i.value = 1

    for i in range(256):
        await source.write(int.to_bytes(i, 1, 'little'))
        await source.wait()

        dut.data_ready_i.value = 1
        await RisingEdge(dut.clk_i)
        assert (dut.data_valid_o.value == 1 and dut.data_o == i)
        await RisingEdge(dut.clk_i)
        await RisingEdge(dut.clk_i)
        assert (dut.data_valid_o.value == 0)
        dut.data_ready_i.value = 0
        await RisingEdge(dut.clk_i)


    for _ in range(10):
        await RisingEdge(dut.clk_i)

@cocotb.test
async def test_uart_trans(dut):
    cocotb.start_soon(Clock(dut.clk_i, 1, 'ns').start())

    source = UartSink(dut.tx_o, baud=100_000_000, bits=8)

    dut.arstn_i.value = 0
    dut.data_valid_i.value = 0
    await RisingEdge(dut.clk_i)
    dut.arstn_i.value = 1

    for i in range(256):
        dut.data_valid_i.value = 1
        dut.data_i.value = i
        await RisingEdge(dut.clk_i)
        dut.data_valid_i.value = 0

        for j in range(100):
            await RisingEdge(dut.clk_i)
