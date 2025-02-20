// Import required packages
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A customizable and responsive date range picker widget that allows users
/// to select date ranges from a predefined list of monthly periods.
/// The widget adapts its layout and styling based on screen size.
class DateRangePickerWidget extends StatefulWidget {
  /// Callback function triggered when a date range is selected
  final Function(DateTimeRange) onDateRangeSelected;
  
  /// Callback function triggered when the search action is initiated
  final VoidCallback onSearch;

  const DateRangePickerWidget({
    super.key,
    required this.onDateRangeSelected,
    required this.onSearch,
  });

  @override
  State<DateRangePickerWidget> createState() => _DateRangePickerWidgetState();
}

class _DateRangePickerWidgetState extends State<DateRangePickerWidget> {
  // Date formatter for displaying dates in MM/dd/yyyy format
  final DateFormat displayFormat = DateFormat('dd/MM/yyyy');
  
  // Controls the visibility of the date range dropdown
  bool isExpanded = false;
  
  // Stores all available monthly date ranges
  List<DateTimeRange> monthRanges = [];
  
  // Currently selected date range
  DateTimeRange? selectedRange;
  
  // Controller for the scrollable list of date ranges
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Generate the list of month ranges when widget initializes
    _generateMonthRanges();
    // Set the initial selected range to the first available range
    selectedRange = monthRanges.first;
  }

  /// Generates monthly date ranges from January 2020 to current date
  void _generateMonthRanges() {
    // Start date set to January 1, 2020
    DateTime start = DateTime(2020, 1, 1);
    // End date set to current date
    DateTime end = DateTime.now();
    DateTime current = start;

    // Generate ranges for each month
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      DateTime firstDay = DateTime(current.year, current.month, 1);
      DateTime lastDay = DateTime(current.year, current.month + 1, 0);
      monthRanges.add(DateTimeRange(start: firstDay, end: lastDay));
      current = DateTime(current.year, current.month + 1, 1);
    }
    // Reverse the list so most recent dates appear first
    monthRanges = monthRanges.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to make the widget responsive
    return LayoutBuilder(
      builder: (context, constraints) {
        // Define small screen threshold (600px width)
        final isSmallScreen = constraints.maxWidth < 600;
        
        return Column(
          children: [
            // Main date picker button container
            Container(
              width: double.infinity,
              // Limit maximum width on larger screens
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? double.infinity : 600,
              ),
              // Responsive margins
              margin: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 0,
                vertical: 8,
              ),
              // Responsive padding
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: 12,
              ),
              // Container styling
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 30),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Calendar icon
                  Icon(
                    Icons.calendar_today,
                    size: isSmallScreen ? 18 : 20,
                    color: Colors.grey.shade600,
                  ),
                  // Responsive spacing
                  SizedBox(width: isSmallScreen ? 12 : 25),
                  // Selected date range display
                  Expanded(
                    child: Text(
                      selectedRange != null
                          ? '${displayFormat.format(selectedRange!.start)} - ${displayFormat.format(selectedRange!.end)}'
                          : 'Select Date Range',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                  ),
                  // Search/expand button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isExpanded = !isExpanded;
                      });
                      if (!isExpanded) {
                        widget.onSearch();
                      }
                    },
                    child: const Icon(
                      Icons.search,
                      size: 24,
                      color: Color(0xFF00CF9D),
                    ),
                  ),
                ],
              ),
            ),
            // Expandable date range list
            if (isExpanded) ...[
              const SizedBox(height: 4),
              Container(
                // Responsive constraints
                constraints: BoxConstraints(
                  maxWidth: isSmallScreen ? double.infinity : 600,
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 0,
                ),
                // Dropdown styling
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Scrollable list of date ranges
                    Flexible(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: monthRanges.length,
                        itemBuilder: (context, index) {
                          final range = monthRanges[index];
                          final isSelected = selectedRange == range;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedRange = range;
                              });
                              widget.onDateRangeSelected(range);
                            },
                            child: Container(
                              // Responsive padding
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12 : 16,
                                vertical: isSmallScreen ? 10 : 12,
                              ),
                              // List item styling
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.transparent,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Left padding for date text
                                  SizedBox(width: isSmallScreen ? 8 : 16),
                                  // Date range text
                                  Expanded(
                                    child: Text(
                                      '${displayFormat.format(range.start)} - ${displayFormat.format(range.end)}',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.black87,
                                        fontSize: isSmallScreen ? 13 : 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Bottom action bar with close button
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                isExpanded = false;
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12 : 16,
                                vertical: isSmallScreen ? 8 : 10,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.close, size: 18, color: Colors.red),
                                SizedBox(width: 4),
                                Text('Close',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Clean up scroll controller when widget is disposed
    _scrollController.dispose();
    super.dispose();
  }
}