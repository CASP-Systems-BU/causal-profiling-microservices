import pyshark
import csv

cap = pyshark.FileCapture('tcpData/final-output.pcap')
csvfile = open("packet_data.csv", 'w')
csvwriter = csv.writer(csvfile)
csvwriter.writerow(['Start Time', 'RTT', 'SRC IP', 'Dest IP', 'Seq', 'Seq Raw'])
count = 0
count_no_ip = 0
for packet in cap:
    if "ip" not in packet:
        count_no_ip = count_no_ip + 1
        continue
    # src_ip = packet.ip.src
    # dest_ip = packet.ip.dst
    # print(str(packet.ip))
    # print(str(dir(packet.frame_info)))
    # print(str(packet.layers))
    try:
        # print(packet[packet.transport_layer].seq)
        csvwriter.writerow([packet.frame_info.time_epoch, packet[packet.transport_layer].analysis_ack_rtt, packet.ip.src,
                            packet.ip.dst, packet[packet.transport_layer].seq, packet[packet.transport_layer].seq_raw])
    except Exception as e:
        csvwriter.writerow(
            [packet.frame_info.time_epoch, -1, packet.ip.src,
             packet.ip.dst, -1, -1])
    count = count + 1
    # if count == 10:
    #     break
print(count)
print(count_no_ip)
csvfile.close()
