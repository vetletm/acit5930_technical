/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;

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
    bit<8>    diffserv; // TOS / DSCP
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
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<3>  res;
    bit<3>  ecn;
    bit<6>  ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

struct metadata {
    bit<32> flow_hash;
    bit<48> flow_tstamp;
    bit<48> flow_tstamp_previous;
    bit<48> time_now;
    bit<48> time_diff;
    bit<8>  packet_count;
    bit<8>  inc_packet_count;
    bit<8>  packet_count_diff;
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

control MyIngress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    /* index: flow_hash, value: first timestamp */
    register<bit<48>>(8192) tstamp_register;
    /* index: flow_hash, value: packet counter */
    register<bit<48>>(8192) packet_counter;

    action drop() {
        mark_to_drop(standard_metadata);
    }

    action check_time() {
        // Checks if time since first packet in epoc is >10,000 (i.e. 10 milliseconds)
        meta.time_now = standard_metadata.ingress_global_timestamp;

        // If current timestamp is 10msec after first tstamp, reset and write packet_count to packet
        meta.time_diff = meta.time_now - meta.flow_tstamp;
        if (meta.time_diff > 10000) {
            meta.flow_tstamp = meta.time_now;
            hdr.ipv4.diffserv = meta.packet_count;

            tstamp_register.write((bit<32>) meta.flow_hash, meta.flow_tstamp)
        }
    }

    action store_ploss() {
        // Stores the difference between current packet counter and incoming packet counter
        if (meta.packet_count < meta.inc_packet_count) {
            meta.packet_count_diff = meta.inc_packet_count - meta.packet_count;
            log_msg("PLOSS: flow_hash={}, pcount = {}, inc_pcount = {}, pcount_diff = {}",
                    {meta.flow_hash, meta.packet_count, meta.inc_packet_count, meta.packet_count_diff}
            );
        }
    }

    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

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
        if (hdr.ipv4.isValid()) {
            ipv4_lpm.apply();
        }
        if (hdr.tcp.isValid()) {
            hash(meta.flow_hash,
                HashAlgorithm.crc16,
                (bit<32>)0,
                { hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.ipv4.protocol, hdr.tcp.srcPort, hdr.tcp.dstPort },
                (bit<32>) 8192);

            // increment packet counter
            packet_counter.read(meta.packet_count, (bit<32>) meta.flow_hash);
            meta.packet_count = meta.packet_count + 1;
            packet_counter.write((bit<32>) meta.flow_hash, meta.packet_count)

            // Set flow_tstamp to 0 before reading from register to check if it is first packet in flow
            meta.flow_tstamp = 0;
            tstamp_register.read(meta.flow_tstamp, (bit<32>) meta.flow_hash);

            // If first packet in flow, tstamp is zero
            if (meta.flow_tstamp == 0) {
                tstamp_register.write((bit<32>) meta.flow_hash, standard_metadata.ingress_global_timestamp)
            } else {
                // If not first packet in flow, check time
                check_time()
            }

            // If incoming packet has TOS field marked, assume its used for ploss and write ploss to logs
            meta.inc_packet_count = hdr.ipv4.diffserv;
            if (meta.inc_packet_count > 0) {
                store_ploss()
            }
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
