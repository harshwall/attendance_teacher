import 'package:attendance_teacher/classes/teacher.dart';
import 'package:attendance_teacher/classes/teaching.dart';
import 'package:attendance_teacher/screens/createclass.dart';
import 'package:attendance_teacher/screens/mailclass.dart';
import 'package:attendance_teacher/screens/profile.dart';
import 'package:attendance_teacher/screens/shortatendancelist.dart';
import 'package:attendance_teacher/screens/subjectlist.dart';
import 'package:attendance_teacher/services/toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {

  Teacher _teacher;

  Dashboard(this._teacher);

  @override
  _DashboardState createState() => _DashboardState(_teacher);
}

class _DashboardState extends State<Dashboard> {

  Teacher _teacher;

  String _url;

  _DashboardState(this._teacher);

  void initState() {
    super.initState();
    getURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxisScrolled) {
            return <Widget>[
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                child: SliverSafeArea(
                  top: false,
                  sliver: SliverAppBar(
                    expandedHeight: 200.0,
                    floating: true,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                        centerTitle: true,

                        title: Text('Dashboard'),
                        background: Card(
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                Align(
                                  alignment: Alignment.center,
                                  child: CircleAvatar(
                                    radius: 50.0,
                                    backgroundColor: Colors.blueAccent,
                                    child: ClipOval(
                                      child: SizedBox(
                                        width: 100.0,
                                        height: 100.0,
                                        child: _url!=null?Image.network(_url):Image.network(
                                          "https://d2x5ku95bkycr3.cloudfront.net/App_Themes/Common/images/profile/0_200.png",
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                    ),
                                  ),

                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      child: Text(
                                        _teacher.name,
                                        textScaleFactor: 1.5,
                                      ),
                                    ),
                                    Container(
                                      child: Text(
                                        _teacher.teacherId,
                                        textScaleFactor: 1.5,
                                      ),
                                    ),
                                    Container(
                                      child: Text(
                                        _teacher.mobile,
                                        textScaleFactor: 1.5,
                                      ),
                                    ),
                                  ],
                                )
                              ]

                          ),
                        )
                    ),
                  ),
                ),
              )

            ];
          },
          body: getSubjects()
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          if(_teacher.verify==0)
            toast('Your profile is not yet verified.');
          else if(_teacher.verify==-1)
            toast('Please correct and update profile');
          else
			Navigator.push(context, MaterialPageRoute(builder: (context) {
				return CreateClass(_teacher);
			}));
        },
        tooltip: 'Create new class',
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            ListTile(
              title: Text('Profile'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return Profile(_teacher);
                }));
              },
            ),
            ListTile(
              title: Text('Sign Out'),
              onTap: () {

              },
            )
          ],
        ),
      ),
    );
  }

  Widget getSubjects() {
    return StreamBuilder<QuerySnapshot> (
      stream: Firestore.instance.collection('teach').document(_teacher.documentId).collection('subject').snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if(!snapshot.hasData)
          return Text('Loading');
        return getSubjectList(snapshot);
      },
    );
  }

  getSubjectList(AsyncSnapshot<QuerySnapshot> snapshot) {

    var listView = ListView.builder(itemCount: snapshot.data.documents.length,itemBuilder: (context, index) {
      if(index<snapshot.data.documents.length) {
        var doc = snapshot.data.documents[index];
        Teaching subject = Teaching.fromMapObject(doc);
        subject.documentId = doc.documentID;
        subject.teacherDocumentId = _teacher.documentId;
//        return GestureDetector(
//          onTap: () {
//
//            Navigator.push(context, MaterialPageRoute(builder: (context) {
//              return SubjectList(_teacher, subject);
//            }));
////            Navigator.push(context, MaterialPageRoute(builder: (context) {
////              return MailClass(subject,_teacher);
////            }));
//
//          },
//          child: Card(
//            child: ListTile(
//              title: Text(subject.subjectId),
//              subtitle: Text(subject.subjectName),
//            ),
//          ),
//        );
        return Card(
          color: Colors.black,
          child: ExpansionTile(
              title: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Text(
                      subject.subjectName,
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subject.classId,
                      style: TextStyle(
                        fontSize: 15.0,
                      ),
                    ),
                  ],
                ),
              ),
              children: <Widget>[
                Column(
                  children: <Widget>[
                    ListTile(
                      title: Text('Attendance'),
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context) {
                          return SubjectList(_teacher, subject);
                        }));
                      },
                    ),
                    ListTile(
                      title: Text('Short Attendance List'),
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context) {
                          return SubjectShortAttendancelist(_teacher, subject);
                        }));
                      },
                    ),
                    ListTile(
                      title: Text('Email CLass'),
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context) {
                          return MailClass(_teacher, subject);
                        }));
                      },
                    ),
                  ],
                )
              ]
          ),
        );
      }
      return GestureDetector();

    });

//
    return listView;
  }

  void getURL() async{
    String url;
    StorageReference ref = FirebaseStorage.instance.ref().child(_teacher.teacherId);
    url = (await ref.getDownloadURL()).toString();
    print(url);

    setState(() {
      _url = url;
    });

  }
}
