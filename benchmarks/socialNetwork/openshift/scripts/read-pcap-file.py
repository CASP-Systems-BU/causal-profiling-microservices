import pyshark
import datetime
import csv
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.pyplot import figure
import numpy as np
from matplotlib.patches import Patch
import networkx as nx


def generate_network_graph():
    df = pd.read_csv("packet_data.csv")
    df1 = df[['SRC IP', 'Dest IP']]
    network_graph = nx.from_pandas_edgelist(df1, 'SRC IP', 'Dest IP',create_using=nx.DiGraph())
    print(df1.head())
    figure(figsize=(10, 8))
    nx.draw_shell(network_graph, with_labels=True)
    plt.show()

def generate_gantt_chart():
    """
    Generate Gantt chart from CSV file
    :return: None
    """
    plt.rcParams.update({'font.size': 3})
    df = pd.read_csv("packet_data.csv")
    df = df.loc[df['RTT'] != -1].head(200)
    unique_ips = df['SRC IP'].unique()
    colors = dict(zip(unique_ips, ["C" + str(i) for i in range(len(unique_ips))]))
    df['color'] = df['SRC IP'].map(colors)
    legend_elements = [Patch(facecolor=colors[i], label=i) for i in colors]
    benchmark_start = df['Start Time'].min()
    # number of days from project start to task start
    df['start_num'] = (df['Start Time'] - benchmark_start)
    # number of days from project start to end of tasks
    df['end_num'] = (df['End Time'] - benchmark_start)
    # days between start and end of each task
    df['days_start_to_end'] = (df.end_num - df.start_num)*1000
    print(df.head())
    fig, ax = plt.subplots(1, figsize=(16, 6))
    # for idx, row in df.iterrows():
    #     # ax.text(row.end_num + 0.1, idx, f"{float(row['days_start_to_end'])}ms", va='center', alpha=0.8)
    #     ax.text(row.start_num, idx, row['Seq Raw'], va='center', ha='right', alpha=0.8)
    ax.legend(handles=legend_elements)
    ax.set_axisbelow(True)
    ax.xaxis.grid(color='gray', linestyle='dashed', alpha=0.2, which='both')
    ax.spines['right'].set_visible(False)
    ax.spines['left'].set_visible(False)
    ax.spines['left'].set_position(('outward', 10))
    ax.spines['top'].set_visible(False)
    plt.suptitle('Benchmark Span')
    ax.barh(df['Seq Raw'].astype(str), df.days_start_to_end, left=df.start_num, color=df.color)
    plt.show()


def read_pcap_file():
    """
    Read pcap file and generate CSV file
    :return: None
    """
    cap = pyshark.FileCapture('tcpData/final-output.pcap')
    csvfile = open("packet_data.csv", 'w')
    csvwriter = csv.writer(csvfile)
    csvwriter.writerow(['Start Time', 'End Time', 'RTT', 'SRC IP', 'Dest IP', 'Seq', 'Seq Raw'])
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
            rtt_time = float(packet[packet.transport_layer].analysis_ack_rtt)
            end_time = datetime.datetime.fromtimestamp(float(packet.frame_info.time_epoch)) + datetime.timedelta(seconds=rtt_time)
            csvwriter.writerow([packet.frame_info.time_epoch, end_time.timestamp(), packet[packet.transport_layer].analysis_ack_rtt,
                                packet.ip.src, packet.ip.dst, packet[packet.transport_layer].seq,
                                packet[packet.transport_layer].seq_raw])
        except Exception as e:
            csvwriter.writerow(
                [packet.frame_info.time_epoch, packet.frame_info.time_epoch, -1, packet.ip.src,
                 packet.ip.dst, count, count])
        count = count + 1
        # if count == 100:
        #     break
    print(count)
    print(count_no_ip)
    csvfile.close()


if __name__ == '__main__':
    # read_pcap_file()
    # generate_gantt_chart()
    generate_network_graph()