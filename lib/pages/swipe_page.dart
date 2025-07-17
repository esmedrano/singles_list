import 'package:flutter/material.dart';
import 'package:integra_date/widgets/filters_menu.dart' as filters_menu;

class SwipePage extends StatefulWidget {
  const SwipePage({
    super.key,
    required this.profiles,
    this.databaseIndex, 
  });

  final Future<List<Map<dynamic, dynamic>>> profiles;
  final int? databaseIndex;

  @ override
  SwipePageState createState() => SwipePageState();
}

class SwipePageState extends State<SwipePage> {
  int profileIndex = 0;

  @override
  void didUpdateWidget(SwipePage oldWidget) {  // Update profileIndex when a banner / grid view is selected in database mode
    super.didUpdateWidget(oldWidget);
    if (widget.databaseIndex != oldWidget.databaseIndex) {
      setState(() {
        profileIndex = widget.databaseIndex ?? 0;  
      });
    }
  }

  @override
  Widget build(BuildContext context) {  // Scoll of profile widgets
    dynamic profiles;
    
    void nextProfile() {
      setState( () {
        profileIndex += 1;  // Iterate to next profile
        if (profileIndex == profiles.length) {
          profileIndex = 0;
        }
      });
    }

    return FutureBuilder<List<Map<dynamic, dynamic>>>(
      future: widget.profiles,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No profiles available'));
        }

        profiles = snapshot.data!;

        return SafeArea(  
          child: ListView(
            padding: EdgeInsets.only(left: 10, right: 10, top: 10),
          
            children: [
              Stack(  
                children: [
                  Center(  // First image
                    child: SizedBox(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),  // Adjust radius for rounded corners
                        child: AspectRatio(aspectRatio: 4/5, child: Image.asset(profiles[profileIndex]['profilePic'], fit: BoxFit.cover))
                      )
                    ),
                  ),
                  
                  Positioned(
                    top: 5,
                    right: 10,
                    child: Container(  // Filters menu
                      alignment: Alignment.topRight,
                      // padding: EdgeInsets.only(right: 0),
                      child: filters_menu.FiltersMenu()
                    ),
                  ),

                  Positioned(  // Dislike button
                    bottom: 20,
                    left: 20,
                    child: SizedBox(
                      width: 90,
                      child: IconButton(
                        onPressed: () {
                          nextProfile();
                        }, 
                        
                        icon: Image.asset('assets/icons/x.png')),
                    ),
                  ),
          
                  Positioned(  // Like button
                    bottom: 20,
                    right: 20,
                    child: SizedBox(
                      width: 100,
                      child: IconButton(
                        onPressed: () {
                          nextProfile();
                        }, 
                        
                        icon: Image.asset('assets/icons/heart.png')),
                    ),
                  ),
                ],
              ),
          
              Padding(  // Basic Info
                padding: const EdgeInsets.only(top: 15, bottom: 15),
                child: Container(  // Background
                  decoration: BoxDecoration(
                    color: Colors.blueGrey,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  
                  child: Column(  // Text
                    children: [
                      SizedBox(height: 25),
                      Row(  // Row one of text with each entry seperated for accurate spacing
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            profiles[profileIndex]['name'],
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ), 
                          ),
          
                          SizedBox(width: 30),
          
                          Text(
                            profiles[profileIndex]['age'],
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ), 
                          ),
          
                          SizedBox(width: 30),
          
                          Text(
                            profiles[profileIndex]['height'],
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ), 
                          ),
                        ],
                      ),
          
                      SizedBox(height: 10),  // Space between the rows
                      
                      Row(  // Row two of text 
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(profiles[profileIndex]['location'], 
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(width: 30),
                          Text(profiles[profileIndex]['distance'], 
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ), 
                          ),
                        ],
                      ),
                      SizedBox(height: 25)
                    ],
                  ),
                ),
              ),
          
              // Display tags
              
              for (var imagePath in profiles[profileIndex]['images'])  // Display all other images
                Column(
                  children: [
                    Stack(
                      children: [
                      
                        Center(
                          child: SizedBox(
                            // width: MediaQuery.of(context).size.width - 80,
                            //height: 589,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10), // Adjust radius for rounded corners
                              child: AspectRatio(aspectRatio: 4/5, child: Image.asset(imagePath, fit: BoxFit.cover,))
                            )
                          ),
                        ),
                        
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: SizedBox(
                            width: 90,
                            child: IconButton(
                              onPressed: () {
                                nextProfile();
                              }, 
                              
                              icon: Image.asset('assets/icons/x.png')),
                          ),
                        ),
                      
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: SizedBox(
                            width: 100,
                            child: IconButton(
                              onPressed: () {
                                nextProfile();
                              }, 
                              
                              icon: Image.asset('assets/icons/heart.png')),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 15),
                  ],
                ),
            ],
          ),
        );
      }
    );  
  }
}