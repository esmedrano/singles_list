import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<File?> images = List.generate(6, (_) => null);  // This list will contain all images for the builder

  final ImagePicker _picker = ImagePicker();  // Image picker instance  
  
  final TextEditingController _controller = TextEditingController();  // Intro box setup
  final FocusNode _focusNode = FocusNode();  // Intro box setup

  final List tagList = ['INTP', ''];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {  // Get image from phone gallery
    var emptySlots = images.where((image) => image == null).length;
    
    if (emptySlots == 0) return; // No empty slots available
      
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          if (images[index] == null) {
            images[index] = File(pickedFile.path);
          }
        });
      }
    } catch(e) {
      print("Error picking image: $e");
    }
  }

  void _removeImage(int index) {  // Remove image
    setState(() {
      images[index] = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        children: [
            Column(
            children: [
              Container(  // Drop down menu for view as profile and changing match preferences
                alignment: Alignment.topRight,
                margin: EdgeInsets.only(right: 10.5),
                child: MenuAnchor(
                  style: MenuStyle(
                    backgroundColor: WidgetStatePropertyAll(Color(0xFFFFFFFF)),
                    elevation: WidgetStatePropertyAll(0),
                    ),
          
                  menuChildren: [
                    MenuItemButton(onPressed: () {}, child: Text('View as profile')),
                    MenuItemButton(onPressed: () {}, child: Text('Preferences'))
                  ],
                  alignmentOffset: Offset(-70, 0),
                  builder: (_, MenuController controller, Widget? child) {
                    return IconButton(
                      onPressed: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                
                      icon: Icon(Icons.more_vert)
                    );
                  }
                ),
              ),
          
              GridView.builder(  // Pictures grid
                shrinkWrap: true,  // Limit total height of the grid to the height of it's children instead of infinity
                physics: NeverScrollableScrollPhysics(),  // Disable scrolling (it's already in a scollable listView (soon))
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3/4,
                ),
                padding:  EdgeInsets.only(left: 10, right: 10),
                itemCount: 6, 
          
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: images[index] == null ? Color(0x50FFFFFF) : null,
                      borderRadius: BorderRadius.circular(8),
                      image: images[index] != null
                        ? DecorationImage(
                          image: FileImage(images[index]!),
                          fit: BoxFit.cover,
                          )
                        : null,
                    ),
          
                    child: Stack(
                      children: [
                        Positioned(
                          top: 1,
                          right: 1,
                          child: IconButton(
                            highlightColor: Color(0x50FFFFFF),
                            splashRadius: 5,
                            icon: Icon(
                              size: 30,
                              images[index] == null ? Icons.add : Icons.close,
                              color: const Color.fromARGB(255, 70, 78, 66),
                            ),
          
                            onPressed: () {
                              if (images[index] == null) {
          
                                _pickImage(index);
                              } else {
                                _removeImage(index);
                              }
                            },
                          )
                        )
                      ]
                    ),
                  );
                }
              ),

              Container(  // Intro
                margin: EdgeInsets.all(10),
                child: TextField( 
                  controller: _controller,
                  focusNode: _focusNode,
                  
                  onTapOutside: (_) {  // Close keyboard and remove cursor 
                      _focusNode.unfocus();
                    },
                  
                  minLines: 5,
                  maxLines: 10,
                
                  style: 
                    TextStyle(
                      fontSize: 14,
                      color: const Color.fromARGB(179, 9, 45, 129), 
                    ),
                  
                  decoration: InputDecoration(
                    hintText: 'Write an intro!', 
                    fillColor: Color(0x50FFFFFF),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                  ),
                
                  onSubmitted: (value) => null,  // Send to database
                  onTap: () => _focusNode.requestFocus(),
                ),
              ),
              
              Container(  // Tags
                margin: EdgeInsets.only(left: 10, right: 10),
                child: Row(
                  children: [
                    Text(  // Section header
                      'Tags',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,              
                      )
                    ),
                    
                    IconButton(  // Add a tag button
                      highlightColor: Color(0x50FFFFFF),
                      splashRadius: 5, 
                      icon: Icon(
                        Icons.add, 
                        size: 30,
                        color: const Color.fromARGB(255, 70, 78, 66),
                      ), 
                
                      onPressed: () {},
                    
                    )
                  ],
                ),
              ) 
            ]
          ),
        ]
      ),
    );
  }
}
