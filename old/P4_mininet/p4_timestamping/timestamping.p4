/* -*- P4_16 -*- */
/* Disclaimer: This p4-code is copied from p4lang/tutorials (exercises/basic/solution) to save time, and I've modified it to reduce TTL by 5 instead of 1 to make it explicitly clear when it has run. */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;
const bit<8>  TYPE_TCP  = 6;

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv; // TOS / DSCP -- Use for timestamping the difference of packet - previous packet
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;  // Use as basis to check current packet against previous packet
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<1>  cwr;
    bit<1>  ece;
    bit<1>  urg;
    bit<1>  ack;
    bit<1>  psh;
    bit<1>  rst;
    bit<1>  syn;
    bit<1>  fin;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

// Standard 5-tuple
// struct flow_id_t {
//     ip4Addr_t   srcAddr;
//     ip4Addr_t   dstAddr;
//     bit<16>     srcPort;
//     bit<16>     dstPort;
//     bit<8>      protocol;
// }
//
// struct timestamp_t {
//     bit<16> flow_hash;
//     bit<32> timestamp;
// }

struct metadata {
    // flow_id_t flow_id;
    // timestamp_t tstamp;
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    tcp_t        tcp;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            TYPE_TCP: parse_tcp;
            default: accept;
        }
    }

    state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }

}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    tuple<bit<16>, bit<32>>

    action drop() {
        mark_to_drop(standard_metadata);
    }

    // timestamping logic
    action tcp_timecheck() {
        // Set current packet regardless of prev_packet
        // meta.curr_packet = { hdr.tcp.seqNo, standard_metadata.enq_timestamp };
        // // if current packet is first in sequence
        // if (meta.curr_packet[0] == 0) {
        //     // set curr_packet as prev_packet and move on to forwarding logic
        //     meta.prev_packet = meta.curr_packet;
        // } else {
        //     // If not first in sequence, assume prev_packet exists and check if sequence number is larger
        //     if (meta.curr_packet[1] > meta.prev_packet[1]) {
        //         // if larger sequence, store timedelta in diffserv and forward packet
        //         meta.time_diff = (bit<8>)(meta.curr_packet[1] - meta.prev_packet[1]);
        //         hdr.ipv4.diffserv = meta.time_diff;
        //     }
        //     // finally set prev_packet as curr_packet and move on to forwarding logic
        //     meta.prev_packet = meta.curr_packet;
        // }
        // meta.curr_packet = {hdr.tcp.seqNo, standard_metadata.enq_timestamp};
        // if (meta.prev_packet) {
        //     meta.prev_packet = meta.curr_packet;
        //     hdr.ipv4.diffserv = 0;
        // } else if (meta.curr_packet[1] > (meta.prev_packet[1])) {
        //     meta.time_diff = (bit<8>)(meta.curr_packet[1] - meta.prev_packet[1]);
        //     hdr.ipv4.diffserv = meta.time_diff;
        // }
        // // Set current packet as previous packet after updating diffserv-field
        // meta.prev_packet = meta.curr_packet;
    }

    // Basic forwarding logic
    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    // table flow_timestamp {
    //     key = {
    //         meta.flow_id: exact;
    //     }
    //     actions = {
    //         tcp_timecheck;
    //         NoAction;
    //     }
    //     default_action = NoAction();
    // }

    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = drop();
    }

    apply {
        // For all valid IP
        if (hdr.ipv4.isValid()) {
            ipv4_lpm.apply();
        }
        // For all valid TCP
        if (hdr.tcp.isValid()) {
            flow_timestamp.apply();
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
     apply {
	update_checksum(
        // If checksum is valid, update with the following fields
	    hdr.ipv4.isValid(),
        { hdr.ipv4.version,
          hdr.ipv4.ihl,
          hdr.ipv4.diffserv,
          hdr.ipv4.totalLen,
          hdr.ipv4.identification,
          hdr.ipv4.flags,
          hdr.ipv4.fragOffset,
          hdr.ipv4.ttl,
          hdr.ipv4.protocol,
          hdr.ipv4.srcAddr,
          hdr.ipv4.dstAddr },
        // Update the checksum if the header is valid
        hdr.ipv4.hdrChecksum,
        // Update with the following algorithm
        HashAlgorithm.csum16);
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
