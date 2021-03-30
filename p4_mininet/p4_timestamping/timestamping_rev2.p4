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
    bit<8>    diffserv;
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
    // bit<32> syn_lastseen;
    // bit<32> flow_counter;
    bit<48> flow_tstamp;
    bit<48> time_now;
    bit<48> time_diff;
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
    /* index: flow hash, value: last timestamp */
    register<bit<48>>(8192) tstamp_register;
    /* index: 0, value: flow counter */
    // register<bit<32>>(1) flow_counter_register;
    /* index: counter, value: flow hash */
    // register<bit<32>>(32w8192) flow_hash_register;
    // /* index: hash, value: flow source IP */
    // register<ip4Addr_t>(32w8192) flow_source_register;
    // /* index: hash, value: flow source port (16 bit) */
    // register<bit<16>>(32w8192) flow_sourceport_register;
    // /* index: hash, value: flow destination IP */
    // register<ip4Addr_t>(32w8192) flow_destination_register;
    // /* index: hash, value: flow destination port (16 bit) */
    // register<bit<16>>(32w8192) flow_destinationport_register;
    // /* timestamp register */
    // register<bit<32>>(32w8192) flow_tstamp_register;

    action save_tstamp_information(){
        /* get flow counter, increment and save */
        // flow_counter_register.read(meta.flow_counter, (bit<32>) 0);
        // meta.flow_counter = meta.flow_counter + 1;
        // /* save flow information to registers */
        // flow_counter_register.write((bit<32>) 0, meta.flow_counter);
        // flow_hash_register.write((bit<32>) meta.flow_counter, meta.flow_hash);
        // flow_source_register.write((bit<32>) meta.flow_hash, hdr.ipv4.srcAddr);
        // flow_sourceport_register.write((bit<32>) meta.flow_hash, hdr.tcp.srcPort);
        // flow_destination_register.write((bit<32>) meta.flow_hash, hdr.ipv4.dstAddr);
        // flow_destinationport_register.write((bit<32>) meta.flow_hash, hdr.tcp.dstPort);

        /* save timestamp per flow */
        meta.time_now = standard_metadata.ingress_global_timestamp;
        if (meta.flow_tstamp == 0) {
            meta.time_diff = 0;
        } else {
            meta.time_diff = meta.time_now - meta.flow_tstamp;
        }
        meta.flow_tstamp = meta.time_now;

        hdr.ipv4.diffserv = (bit<8>) meta.time_diff;


        // hdr.ipv4.diffserv = (bit<8>) meta.flow_hash;

        // tstamp_register.write((bit<32>) meta.flow_hash, meta.flow_tstamp);

        // tstamp_register.write((bit<32>) meta.flow_hash, meta.flow_tstamp);
    }

    action drop() {
        mark_to_drop(standard_metadata);
    }

    // Basic forwarding logic
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
            // If first packet in flow
            // if ((hdr.tcp.syn == 1 && hdr.tcp.ack == 1) || (hdr.tcp.syn == 1 && hdr.tcp.ack == 0)) {
            //     meta.flow_tstamp = standard_metadata.enq_timestamp;
            //     tstamp_register.write((bit<32>) meta.flow_hash, meta.flow_tstamp);
            //
            //
            // } else {
            // }
            @atomic {
                hash(meta.flow_hash,
                    HashAlgorithm.crc16,
                    (bit<32>)0,
                    { hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.ipv4.protocol, hdr.tcp.srcPort, hdr.tcp.dstPort },
                    (bit<32>) 256);
                meta.flow_tstamp = 0;
                // flow_counter_register.read(meta.flow_counter, (bit<32>) 0);
                // meta.flow_counter = meta.flow_counter + 1;
                // flow_counter_register.write((bit<32>) 0, meta.flow_counter);

                tstamp_register.read(meta.flow_tstamp, (bit<32>) meta.flow_hash);
                save_tstamp_information();
                tstamp_register.write((bit<32>) meta.flow_hash, meta.flow_tstamp);
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
