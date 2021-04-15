import matplotlib
import matplotlib.pyplot as plt

# Use SVG as default renderer
matplotlib.use('svg')


def save_fig(data, fig_labels, title, ylabel, fig_name):
    """
    Draws and saves figure with given data, labels, title, and given figure name
    :param data: Dataframe to draw
    :param fig_labels: Labels along the X axis, representing each column drawn
    :param title: Title of the figure
    :param ylabel: Scale, metric, or similar
    :param fig_name: Name to save the figure as on disk
    :return: None
    """
    fig = plt.figure(figsize=(10, 10))
    plt.boxplot(data, labels=fig_labels)
    plt.title(title)
    plt.grid()
    plt.ylabel(ylabel)
    plt.savefig(fig_name)
    plt.close(fig)


def interleave_lists(l1, l2):
    """
    Will interleave two lists of the same length.
    If l1 = [a, b, c], l2 = [1, 2, 3]
    result = [a, 1, b, 2, c, 3]
    :param l1: List with arbitrary elements
    :param l2: List with arbitrary elements and equal length as l1
    :return: Interleaved list of l1 + l2
    """
    return [val for pair in zip(l1, l2) for val in pair]
