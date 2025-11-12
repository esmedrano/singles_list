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
  final int filteredPageCount;

  const PaginationButtons({
    super.key,
    required this.currentPage,
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.pageCount,
    required this.filteredPageCount,
  });

  @override
  _PaginationButtonsState createState() => _PaginationButtonsState();
}

class _PaginationButtonsState extends State<PaginationButtons> {
  bool _nextPagePressed = false;
  bool allowNextPageDuringQuery = false;  
  
  // void rebuildPaginatorAfterInitialQuery() {
  //   setState(() {

  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // print('page count: ${widget.pageCount}');
    // print('built paginators. Loading: ${!runningRings || widget.currentPage != widget.pageCount}, Next button: ${widget.hasNextPage && !_nextPagePressed && !runningRings || allowNextPageDuringQuery}');
    // print('filter: ${widget.currentPage != widget.filteredPageCount}, ${widget.currentPage}, ${widget.filteredPageCount}');
    // print(allowNextPageDuringQuery);
    // print(widget.hasNextPage && !_nextPagePressed && !runningRings && widget.currentPage != widget.filteredPageCount || allowNextPageDuringQuery);
    
    // print('filteredPageCount: ${widget.filteredPageCount}');
    // print('widget.hasNextPage: ${widget.hasNextPage}');
    // print('!_nextPagePressed: ${!_nextPagePressed}');
    // print('!runningRings: ${!runningRings}');
    // print('widget.currentPage, widget.filteredPageCount: ${widget.currentPage}, ${widget.filteredPageCount}');
    // print('widget.currentPage != widget.filteredPageCount: ${widget.currentPage != widget.filteredPageCount}');
    // print('allowNextPageDuringQuery: ${allowNextPageDuringQuery}');

    if (widget.currentPage < widget.pageCount) {  // This checks if the next page is still within the cache and if so, allows pagination up to the end of the cache while a query is in progress 
      allowNextPageDuringQuery = true;
    }

    if (widget.currentPage == widget.filteredPageCount) {
      allowNextPageDuringQuery = false;
    }
    
    int selectedIndex = widget.currentPage - 1; // Track the selected index
    int indexHolder = selectedIndex;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: 75,
          child: ElevatedButton(
            onPressed: widget.hasPreviousPage && !_nextPagePressed 
              ? () {
                  widget.onPreviousPage();
                }
              : null,
            style: ButtonStyle(
              backgroundColor: widget.hasPreviousPage && !_nextPagePressed 
                ? WidgetStatePropertyAll(Color.fromARGB(255, 151, 160, 210))
                : null
            ),
            child: const Icon(Icons.arrow_back),
          ),
        ),
    
        GestureDetector(
          onTap: () {
            showCupertinoModalPopup(
              context: context,
              barrierDismissible: true, // Allows dismissal by tapping outside
              
              builder: (BuildContext context) {
                return Container(
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                    color: Color(0xDDFFFFFF),
                  ),
                  child: Padding(
                    padding: EdgeInsetsGeometry.only(bottom: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 50,
                            scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                selectedIndex = index;
                              });
                            },
                            children: List<Widget>.generate(widget.filteredPageCount, (int index) {
                              return Center(child: Text('${index + 1} of ${widget.filteredPageCount}'));
                            }),
                          ),
                        ),
                        
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          style: TextButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                          child: Text('Apply'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ).then((_) {  // Update the page with the picker selection
              if(mounted) {
                setState(() {
                  if (selectedIndex > indexHolder) {
                    widget.onNextPage(selectedIndex + 1);
                    _nextPagePressed = true;
                  }
          
                  if (selectedIndex < indexHolder) {
                    widget.onPreviousPage(selectedIndex + 1);
                  }
                });
              }
            });
          },
          child: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 151, 160, 210),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text('${widget.currentPage} of ${widget.filteredPageCount}', style: TextStyle(fontSize: 16)),
          ),
        ),
    
        SizedBox(
          width: 75,
          child: (!runningRings || widget.currentPage != widget.pageCount) && (widget.pageCount != 0 || !runningRings) 
            ? ElevatedButton(  // The next button is set up so that it can only be pressed once per build tracked by bool _nextPagePressed
                onPressed: widget.hasNextPage && !_nextPagePressed && !runningRings && widget.currentPage != widget.filteredPageCount || allowNextPageDuringQuery  // If there is a next page, and it has not already been pressed this build, and the rings are not running during the initial run, then allow another press of next page
                  ? () {
                      widget.onNextPage();
                      setState(() {
                        _nextPagePressed = true;
                      });
                    }
                  : null,
                style: ButtonStyle(
                  backgroundColor: !runningRings && widget.currentPage != widget.pageCount && widget.currentPage != widget.filteredPageCount || allowNextPageDuringQuery
                    ? WidgetStatePropertyAll(Color.fromARGB(255, 151, 160, 210))
                    : null
                ),
                child: Icon(Icons.arrow_forward),
              )
            : Center(child: CircularProgressIndicator())
        )
      ],
    );
  }
}