import argparse
import re
import sys
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

regex = re.compile(r'\s+([0-9.]+)\s+([0-9.]+)\s+([0-9.]+)\s+([0-9.]+)')
filename = re.compile(r'(.*/)?([^.]*)(\.\w+\d+)?')


def parse_percentiles( file ):
    lines       = [ line for line in open(file) if re.match(regex, line)]
    values      = [ re.findall(regex, line)[0] for line in lines]
    pctles      = [ (float(v[0]), float(v[1]), int(v[2]), float(v[3]), float(v[2])*float(v[0])) for v in values]
    percentiles = pd.DataFrame(pctles, columns=['Latency', 'Percentile', 'TotalCount', 'inv-pct', 'TotalLatency'])
    return percentiles

def parse_files( files ):
    return [ parse_percentiles(file) for file in files]


def info_text(name, data):
    textstr = '%-18s\n------------------\n%-6s = %6.2f ms\n%-6s = %6.2f ms\n%-6s = %6.2f ms\n'%(
        name,
        "min",    data['Latency'].min(),
        "median", data.iloc[(data['Percentile'] - 0.5).abs().argsort()[:1]]['Latency'],
        "max",    data['Latency'].max())
    return textstr


def info_box(ax, text):
    props = dict(boxstyle='round', facecolor='lightcyan', alpha=0.5)

    # place a text box in upper left in axes coords
    ax.text(0.05, 0.95, text, transform=ax.transAxes,
        verticalalignment='top', bbox=props, fontname='monospace')


def plot_summarybox( ax, percentiles, labels ):
    # add info box to the side
    textstr = '\n'.join([info_text(labels[i], percentiles[i]) for i in range(len(labels))])
    info_box(ax, textstr)


def plot_percentiles( percentiles, labels ):
    fig, ax = plt.subplots(figsize=(16,8))
    # plot values
    for data in percentiles:
        ax.plot(data['Percentile'], data['Latency'])

    # set axis and legend
    ax.grid()
    ax.set(xlabel='Percentile',
           ylabel='Latency (milliseconds)',
           title='Latency Percentiles (lower is better)')
    ax.set_xscale('logit')
    plt.xticks([0.25, 0.5, 0.9, 0.99, 0.999, 0.9999, 0.99999, 0.999999])
    majors = ["25%", "50%", "90%", "99%", "99.9%", "99.99%", "99.999%", "99.9999%"]
    ax.xaxis.set_major_formatter(ticker.FixedFormatter(majors))
    ax.xaxis.set_minor_formatter(ticker.NullFormatter())
    plt.legend(bbox_to_anchor=(0., 1.02, 1., .102),
               loc=3, ncol=2,  borderaxespad=0.,
               labels=labels)

    return fig, ax


def arg_parse():
    parser = argparse.ArgumentParser(description='Plot HDRHistogram latencies.')
    parser.add_argument('files', nargs='+', help='list HDR files to plot')
    parser.add_argument('--output', default='latency.png',
                        help='Output file name (default: latency.png)')
    parser.add_argument('--title', default='', help='The plot title.')
    parser.add_argument("--nobox", help="Do not plot summary box",
                        action="store_true")
    args = parser.parse_args()
    return args


if __name__ == '__main__':
    args = arg_parse()
    base_names = []
    labels = []
    for file in args.files:
        file_split = file.split(":")
        print(file_split)
        base_names.append(file_split[1])
        labels.append(file_split[0])
    final_data_frames = []
    for base_file_name in base_names:
        data_frames = []
        for i in range(1, 7):
            data_frames.append(parse_percentiles(base_file_name.format(i)))
        new_df = pd.concat(data_frames).groupby(["Percentile", "inv-pct"], as_index=False).agg(
            {'TotalCount': 'sum', 'TotalLatency': 'sum'}
        )
        latency = new_df['TotalLatency'] / new_df['TotalCount']
        new_df['Latency'] = latency
        new_df.drop('TotalLatency', axis=1, inplace=True)
        final_data_frames.append(new_df)
    # for df in final_data_frames:
    #     print(df)
    fig, ax = plot_percentiles(final_data_frames, labels)
    # add title
    plt.suptitle(args.title)
    # save image
    plt.savefig(args.output)
    print("Wrote: " + args.output)

# Jaeger:benchmark-exp-logs/no-tracing-exp/jaeger-benchmark--40-{}.log No-tracing:benchmark-exp-logs/no-tracing-exp/no-tracing-benchmark-40-{}.log TCPDump:benchmark-exp-logs/no-tracing-exp/tcpdump-benchmark-40-{}.log