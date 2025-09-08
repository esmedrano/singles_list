import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;

// This turns off both pagination buttons if a query is occurring
bool runningRings = false;
void toggleRings(bool running) {
  runningRings = running;
}

class PaginationButtons extends StatefulWidget {
  final int currentPage;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final Function([int?]) onPreviousPage;
  final Function([int?]) onNextPage;
  final int pageCount;

  const PaginationButtons({
    super.key,
    required this.currentPage,
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.pageCount,
  });

  @override
  _PaginationButtonsState createState() => _PaginationButtonsState();
}

class _PaginationButtonsState extends State<PaginationButtons> {
  bool _nextPagePressed = false;
  bool allowNextPageDuringQuery = false;  

  @override
  Widget build(BuildContext context) {
    if (widget.currentPage < widget.pageCount) {  // This checks if the next page is still within the cache and if so, allows pagination up to the end of the cache while a query is in progress 
      allowNextPageDuringQuery = true;
    }
    
    int selectedIndex = widget.currentPage - 1; // Track the selected index
    int indexHolder = selectedIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: widget.hasPreviousPage && !_nextPagePressed 
              ? () {
                  widget.onPreviousPage();
                }
              : null,
            child: const Icon(Icons.arrow_back),
          ),

          GestureDetector(
            onTap: () {
              showCupertinoModalPopup(
                context: context,
                barrierDismissible: true, // Allows dismissal by tapping outside
                builder: (BuildContext context) {
                  return Container(
                    height: 200,
                    color: CupertinoColors.white,
                    child: CupertinoPicker(
                      itemExtent: 40,
                      scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                      onSelectedItemChanged: (int index) {
                        setState(() {
                          selectedIndex = index; // Update selected index
                        });
                      },
                      children: List<Widget>.generate(widget.pageCount, (int index) {
                        return Center(child: Text('${index + 1} of ${widget.pageCount}'));
                      }),
                    ),
                  );
                },
              ).then((_) {
                // Ensure the popup is closed before updating the UI
                setState(() {
                  if (selectedIndex > indexHolder) {
                    widget.onNextPage(selectedIndex + 1);
                    _nextPagePressed = true;
                  }

                  if (selectedIndex < indexHolder) {
                    widget.onPreviousPage(selectedIndex + 1);
                  }
                });
              });
            },
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text('${widget.currentPage} of ${widget.pageCount}', style: TextStyle(fontSize: 16)),
            ),
          ),

          //!_nextPagePressed && !runningRings ? Text('Page ${widget.currentPage}') : Center(child: CircularProgressIndicator()),  
          
          ElevatedButton(  // The next button is set up so that it can only be pressed once per build tracked by bool _nextPagePressed
            onPressed: widget.hasNextPage && !_nextPagePressed && !runningRings || allowNextPageDuringQuery  // If there is a next page, and it has not already been pressed this build, and the rings are not running during the initial run, then allow another press of next page
                ? () {
                    widget.onNextPage();
                    setState(() {
                      _nextPagePressed = true;
                    });
                  }
                : null,
            child: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}