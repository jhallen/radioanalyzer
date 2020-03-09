// These parameters define the internal bus

parameter BUS_DATA_WIDTH = 32;
parameter BUS_ADDR_WIDTH = 32;

// Bus input bits

parameter BUS_WR_DATA_START = 0; // Write data
parameter BUS_WR_DATA_END = BUS_WR_DATA_START + BUS_DATA_WIDTH;

parameter BUS_ADDR_START = BUS_WR_DATA_END; // Address
parameter BUS_ADDR_END = BUS_ADDR_START + BUS_ADDR_WIDTH;

parameter BUS_IN_CTRL_START = BUS_ADDR_END; // Control bits
parameter BUS_IN_CTRL_END = BUS_IN_CTRL_START + 7;

parameter BUS_FIELD_RESET_L = BUS_IN_CTRL_START + 0; // Synchronous
parameter BUS_FIELD_CLK = BUS_IN_CTRL_START + 1; // Clock
parameter BUS_FIELD_RE = BUS_IN_CTRL_START + 2; // Read enable
parameter BUS_FIELD_WE = BUS_IN_CTRL_START + 3; // Write enables

parameter BUS_IN_WIDTH = BUS_IN_CTRL_END;

// Bus output bits

parameter BUS_RD_DATA_START = 0; // Read data
parameter BUS_RD_DATA_END = BUS_RD_DATA_START + BUS_DATA_WIDTH;
parameter BUS_OUT_CTRL_START = BUS_RD_DATA_END; // Control bits
parameter BUS_OUT_CTRL_END = BUS_OUT_CTRL_START + 3;

parameter BUS_OUT_WIDTH = BUS_OUT_CTRL_END;

parameter BUS_FIELD_WR_ACK = BUS_OUT_CTRL_START + 0; // Write ack
parameter BUS_FIELD_RD_ACK = BUS_OUT_CTRL_START + 1; // Read ack
parameter BUS_FIELD_IRQ = BUS_OUT_CTRL_START + 2; // IRQ
