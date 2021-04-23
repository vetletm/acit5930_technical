# import matplotlib
import matplotlib.pyplot as plt

# Use SVG as default renderer
# matplotlib.use('png')


def save_boxplot(data, fig_labels, title, ylabel, fig_name):
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


def save_scatterplot(x, y, title, ylabel, xlabel, fig_name):
    """
    Draws and saves a scatterplot with given parameters
    :param x: Data to plot in x
    :param y: Data to plot in y
    :param title: Title of the figure
    :param ylabel: Y label
    :param xlabel: X label
    :param fig_name: Name to save as
    :return: None
    """
    fig = plt.figure(figsize=(10, 10))
    plt.scatter(x, y)
    plt.title(title)
    plt.ylabel(ylabel)
    plt.xlabel(xlabel)
    plt.savefig(fig_name)
    plt.close(fig)


def save_scatter_with_line_regr(x, y, m, b, title, ylabel, xlabel, eq_label, fig_name):
    """
    Takes x, y and draws scatter plot with line regression
    :param x: Data to plot in x
    :param y: Data to plot in y
    :param m: Slope
    :param b: Intercept
    :param title: Title of the figure
    :param ylabel: Y label
    :param xlabel: X label
    :param eq_label: Equation of fit
    :param fig_name: Name to save as
    :return: None
    """
    fig = plt.figure(figsize=(10, 10))
    plt.plot(x, y, 'o')
    plt.plot(x, m*x + b, label=eq_label)
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.title(title)
    plt.grid(True)
    plt.legend(fontsize='small')
    plt.savefig(fig_name)
    plt.close(fig)


def save_histogram(x, y, bins, title, xlabel, fig_name):
    """
    Draws two histograms side by side
    :param x: Data for first
    :param y: Data for second
    :param bins: N bins
    :param title: Title of the histograms
    :param xlabel: Label of X
    :param fig_name: Name to save figure as on disk
    :return: None
    """
    fig, axs = plt.subplots(1, 2, sharey=True, sharex=True, tight_layout=True)
    axs[0].hist(x, bins=bins)
    axs[1].hist(y, bins=bins)
    axs[0].set_title('time_diff')
    axs[0].set_xlabel(xlabel)
    axs[1].set_title('inc_time_diff')
    axs[1].set_xlabel(xlabel)
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
