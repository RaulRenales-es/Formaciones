import logging
import os

from pymodbus.datastore import ModbusSequentialDataBlock, ModbusServerContext, ModbusSlaveContext
from pymodbus.device import ModbusDeviceIdentification
from pymodbus.server import StartTcpServer

from register_map import HOLDING_REGISTERS, PLC_ID, PLC_NAME

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s [%(levelname)s] %(name)s - %(message)s",
)
logger = logging.getLogger(PLC_NAME)


if __name__ == "__main__":
    host = os.getenv("MODBUS_HOST", "0.0.0.0")
    port = int(os.getenv("MODBUS_PORT", "15021"))

    store = ModbusSlaveContext(hr=ModbusSequentialDataBlock(0, HOLDING_REGISTERS))
    context = ModbusServerContext(slaves={PLC_ID: store}, single=False)

    identity = ModbusDeviceIdentification()
    identity.VendorName = "OTLab"
    identity.ProductCode = "SOLAR-PLC"
    identity.ProductName = PLC_NAME
    identity.ModelName = "PyModbus PLC Simulator"

    logger.info("Starting %s on %s:%s with unit id %s", PLC_NAME, host, port, PLC_ID)
    StartTcpServer(context=context, identity=identity, address=(host, port))
