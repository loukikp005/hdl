// ***************************************************************************
// ***************************************************************************
// Copyright 2014 - 2017 (c) Analog Devices, Inc. All rights reserved.
//
// In this HDL repository, there are many different and unique modules, consisting
// of various HDL (Verilog or VHDL) components. The individual modules are
// developed independently, and may be accompanied by separate and unique license
// terms.
//
// The user should read each of these license terms, and understand the
// freedoms and responsibilities that he or she has by using this source/core.
//
// This core is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE.
//
// Redistribution and use of source or resulting binaries, with or without modification
// of this file, are permitted under one of the following two license terms:
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory
//      of this repository (LICENSE_GPL2), and also online at:
//      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
//
// OR
//
//   2. An ADI specific BSD license, which can be found in the top level directory
//      of this repository (LICENSE_ADIBSD), and also on-line at:
//      https://github.com/analogdevicesinc/hdl/blob/master/LICENSE_ADIBSD
//      This will allow to generate bit files and not release the source code,
//      as long as it attaches to an ADI device.
//
// ***************************************************************************
// ***************************************************************************

module dmac_dest_fifo_inf #(

  parameter ID_WIDTH = 3,
  parameter DATA_WIDTH = 64,
  parameter BEATS_PER_BURST_WIDTH = 4)(

  input clk,
  input resetn,

  input enable,
  output enabled,

  input [ID_WIDTH-1:0] request_id,
  output [ID_WIDTH-1:0] response_id,
  output [ID_WIDTH-1:0] data_id,
  input data_eot,
  input response_eot,

  input en,
  output reg [DATA_WIDTH-1:0] dout,
  output reg valid,
  output reg underflow,

  output xfer_req,

  output fifo_ready,
  input fifo_valid,
  input [DATA_WIDTH-1:0] fifo_data,

  input req_valid,
  output req_ready,
  input [BEATS_PER_BURST_WIDTH-1:0] req_last_burst_length,

  output response_valid,
  input response_ready,
  output response_resp_eot,
  output [1:0] response_resp
);

wire data_enabled;

wire [DATA_WIDTH-1:0]  dout_s;
wire data_ready;
wire data_valid;

assign data_ready = en & (data_valid | ~enable);

dmac_data_mover # (
  .ID_WIDTH(ID_WIDTH),
  .DATA_WIDTH(DATA_WIDTH),
  .BEATS_PER_BURST_WIDTH(BEATS_PER_BURST_WIDTH),
  .DISABLE_WAIT_FOR_ID(0)
) i_data_mover (
  .clk(clk),
  .resetn(resetn),

  .enable(enable),
  .enabled(data_enabled),
  .xfer_req(xfer_req),

  .request_id(request_id),
  .response_id(data_id),
  .eot(data_eot),

  .req_valid(req_valid),
  .req_ready(req_ready),
  .req_last_burst_length(req_last_burst_length),

  .s_axi_ready(fifo_ready),
  .s_axi_valid(fifo_valid),
  .s_axi_data(fifo_data),
  .m_axi_ready(data_ready),
  .m_axi_valid(data_valid),
  .m_axi_data(dout_s),
  .m_axi_last()
);

always @(posedge clk) begin
  if (en) begin
    dout <= (data_valid) ? dout_s : {DATA_WIDTH{1'b0}};
    valid <= data_valid & enable;
    underflow <= ~(data_valid & enable);
  end else begin
    valid <= 1'b0;
    underflow <= 1'b0;
  end
end

dmac_response_generator # (
  .ID_WIDTH(ID_WIDTH)
) i_response_generator (
  .clk(clk),
  .resetn(resetn),

  .enable(data_enabled),
  .enabled(enabled),

  .request_id(data_id),
  .response_id(response_id),

  .eot(response_eot),

  .resp_valid(response_valid),
  .resp_ready(response_ready),
  .resp_eot(response_resp_eot),
  .resp_resp(response_resp)
);

endmodule
