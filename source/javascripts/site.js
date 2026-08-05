// RubyBench shared chart utilities
var RubyBench = (function() {
  'use strict';

  // Convert 20250908 or "20250908" to "2025-09-08"
  function formatDate(date) {
    var n = Number(date);
    var year = Math.floor(n / 10000);
    var month = Math.floor(n / 100) % 100;
    var day = n % 100;
    return String(year) + '-' + String(month).padStart(2, '0') + '-' + String(day).padStart(2, '0');
  }

  // Initialize Highcharts defaults
  function initHighchartsDefaults() {
    Highcharts.setOptions({
      lang: { thousandsSep: '' }
    });
  }

  // Create base chart configuration
  function createBaseChartConfig(graphElement, options) {
    var defaultConfig = {
      chart: {
        zoomType: 'x',
        type: options.graphType || 'line',
        animation: false
      },
      title: {
        text: options.title || ''
      },
      yAxis: {
        min: 0,
        title: {
          text: options.yAxisTitle || 'seconds'
        }
      },
      xAxis: {
        categories: options.categories || []
      },
      tooltip: options.tooltip || {},
      series: options.series || [],
      plotOptions: {
        series: {
          animation: false
        },
        line: {
          connectNulls: options.connectNulls !== undefined ? options.connectNulls : true
        }
      }
    };

    // Add xAxis labels if provided
    if (options.xAxisLabels) {
      defaultConfig.xAxis.labels = options.xAxisLabels;
    }

    // Add xAxis title if provided
    if (options.xAxisTitle) {
      defaultConfig.xAxis.title = { text: options.xAxisTitle };
    }

    // Add legend if provided
    if (options.legend) {
      defaultConfig.legend = options.legend;
    }

    // Add plot lines if provided
    if (options.yAxisPlotLines) {
      defaultConfig.yAxis.plotLines = options.yAxisPlotLines;
    }

    return defaultConfig;
  }

  // Plot a Highcharts chart
  function plotChart(graphElement, config) {
    initHighchartsDefaults();

    // Ensure the element is visible before Highcharts measures it
    if (!graphElement.is(':visible')) {
      graphElement.show();
    }

    // Use the DOM element directly instead of ID string
    // graphElement is a jQuery object, so get the first DOM element
    var domElement = graphElement.get(0);
    if (!domElement) {
      console.error('Chart container element not found');
      return null;
    }

    try {
      return Highcharts.chart(domElement, config);
    } catch(e) {
      console.error('Highcharts error:', e);
      console.error('Config was:', config);
      graphElement.html('<div style="padding: 100px; text-align: center; color: red;">Chart rendering failed: ' + e.message + '</div>');
      return null;
    }
  }

  // Move between the .active element's siblings with the left/right arrow keys.
  // `links` is a function returning the elements to navigate, and `activate` is
  // called with the element that an arrow key moved to.
  function setupArrowKeyNavigation(links, activate) {
    $(document).on('keydown', function(event) {
      if (event.key !== 'ArrowLeft' && event.key !== 'ArrowRight') {
        return;
      }
      if (event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) {
        return;
      }
      if ($(event.target).closest('input, textarea, select, [contenteditable="true"]').length > 0) {
        return;
      }

      var elements = links();
      var activeIndex = elements.index(elements.filter('.active'));
      var nextIndex = activeIndex + (event.key === 'ArrowLeft' ? -1 : 1);
      if (activeIndex < 0 || nextIndex < 0 || nextIndex >= elements.length) {
        return;
      }

      event.preventDefault();
      activate(elements.eq(nextIndex));
    });
  }

  // Handle benchmark navigation
  function setupBenchmarkNavigation(options) {
    var activateChart = options.activateChart;
    var defaultBenchmark = options.defaultBenchmark;
    var enableKeyboardNavigation = options.enableKeyboardNavigation;

    function activateBenchmarkLink(link) {
      $('.benchmark_navbar .nav-link').removeClass('active');
      link.addClass('active');
      var id = link.data('id');
      var graphElement = $("#" + id);
      activateChart(graphElement);
      window.location.hash = id;
    }

    // Switch active tab and render it
    $('.activate-chart').on('click', function(event) {
      event.preventDefault();
      activateBenchmarkLink($(this));
    });

    if (enableKeyboardNavigation) {
      setupArrowKeyNavigation(function() {
        return $('.benchmark_navbar .nav-link');
      }, activateBenchmarkLink);
    }

    // Handle URL hash navigation
    function handleHashNavigation() {
      var url = document.location.toString();
      if (url.match('#')) {
        var id = url.split('#')[1];
        $('.benchmark_navbar .nav-link').removeClass('active');
        var graphElement = $('#' + id);
        if (graphElement.length > 0) {
          activateChart(graphElement);
          $('.activate-chart[data-id="' + id + '"]').addClass('active');
        } else if (defaultBenchmark) {
          // Default to first if hash doesn't match
          activateChart(defaultBenchmark);
          $('.benchmark_navbar .nav-link').first().addClass('active');
        }
      } else if (defaultBenchmark) {
        activateChart(defaultBenchmark);
        $('.benchmark_navbar .nav-link').first().addClass('active');
      }
    }

    return {
      handleHashNavigation: handleHashNavigation
    };
  }

  // Setup metric type radio buttons
  function setupMetricTypeHandlers(callback) {
    $('input[name="metric_type"]').on('change', function(event) {
      callback(event);
    });
  }

  // Get active benchmark ID from navbar
  function getActiveBenchmarkId() {
    return $('.benchmark_navbar .nav-link.active').data('id');
  }

  // Get selected metric type
  function getSelectedMetricType() {
    return $('input[name="metric_type"]:checked').val();
  }

  // Show loading indicator
  function showLoading(graphElement, message) {
    message = message || 'Loading data...';
    graphElement.html('<div style="padding: 100px; text-align: center;">' + message + '</div>');
  }

  // Show error message
  function showError(graphElement, message) {
    graphElement.html('<div style="padding: 100px; text-align: center;">' + message + '</div>');
  }

  // Hide all benchmark graphs except the specified one
  function showOnlyGraph(graphElement) {
    $('.benchmark_graph').hide();
    graphElement.show();
  }

  // Public API
  return {
    formatDate: formatDate,
    initHighchartsDefaults: initHighchartsDefaults,
    createBaseChartConfig: createBaseChartConfig,
    plotChart: plotChart,
    setupArrowKeyNavigation: setupArrowKeyNavigation,
    setupBenchmarkNavigation: setupBenchmarkNavigation,
    setupMetricTypeHandlers: setupMetricTypeHandlers,
    getActiveBenchmarkId: getActiveBenchmarkId,
    getSelectedMetricType: getSelectedMetricType,
    showLoading: showLoading,
    showError: showError,
    showOnlyGraph: showOnlyGraph
  };
})();
