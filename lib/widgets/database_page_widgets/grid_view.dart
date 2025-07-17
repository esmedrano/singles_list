import 'package:flutter/material.dart';

class BoxView extends StatelessWidget {
  const BoxView({
    super.key,
    required this.scrollController,
    required this.profileData,
    required this.isLoading,
    required this.initialOffset,
    required this.onBannerTap
  });

  final scrollController;
  final Future<List<Map<dynamic, dynamic>>> profileData;  
  final bool isLoading;
  final initialOffset;
  final Function(int, int?) onBannerTap;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients && scrollController.offset != initialOffset) {
        scrollController.jumpTo(initialOffset.clamp(
          0.0, scrollController.position.maxScrollExtent
        ));
      }
    });

    return FutureBuilder<List<Map<dynamic, dynamic>>>(
      future: profileData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No profiles available'));
        }

        final profiles = snapshot.data!;

        return GridView.builder(
          controller: scrollController,
          itemCount: profiles.length + (isLoading ? 1 : 0),

          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),

          itemBuilder: (context, index) {
            if (index == profiles.length) {
              return Center(child: CircularProgressIndicator());
            }
            return InkWell(
              onTap: () {
                onBannerTap(1, index);
              },

              onLongPress: null,  // ??

              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(  // Main box and image
                        
                        margin: EdgeInsets.only(left: 1, right: 1, bottom: 1),
                        decoration: BoxDecoration(
                          color: Color(0x50FFFFFF),
                        ),
                        
                        child: AspectRatio(  // image at aspect  ratio 1 to match the grid aspect ratio
                          aspectRatio: 1, 
                          child: Image.asset(profiles[index]['profilePic'], fit: BoxFit.cover,)
                        ), 
                      ),
                      
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Container(
                          padding: EdgeInsets.only(left: 3, right: 3, bottom: 1),
                          decoration: BoxDecoration(
                            color: Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(10),
                          ),

                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(  // Name
                                    profiles[index]['name'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                    ),
                                  ),
                                              
                                  Row(  // Age, height, and distance
                              
                                    children: [
                                      Text(  // Age
                                        profiles[index]['age'],
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.black,
                                        ),
                                      ),
                                                                              
                                      Text(  // Height
                                        profiles[index]['height'],
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ]
                                  )
                                ]  
                              ),
                              
                              Text(  // Distance
                                profiles[index]['distance'],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ]
                  ),
                ],
              ),
            );
          },
        );
      }
    );
  }
}