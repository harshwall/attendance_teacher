import 'dart:io';

import 'package:attendance_teacher/classes/teacher.dart';
import 'package:attendance_teacher/classes/teaching.dart';
import 'package:attendance_teacher/classes/timings.dart';
import 'package:attendance_teacher/screens/adminDashboard.dart';
import 'package:attendance_teacher/screens/dashboard.dart';
import 'package:attendance_teacher/services/password.dart';
import 'package:attendance_teacher/services/toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FirestoreCRUD{
	//  This function looks for the document for login
	static Future<QuerySnapshot> getDocsForLogin(Teacher teacher,String inputPass) async {
		return await Firestore.instance.collection('teach')
			.where('teacherId', isEqualTo: teacher.teacherId)
			.where('pass', isEqualTo: await compute(Password.getHash,inputPass)).getDocuments();
	}


	//This function is called for login
	static Future<bool> login(BuildContext context,Teacher teacher,inputPass) async {

		Teacher incoming = Teacher.blank();

		await FirestoreCRUD.getDocsForLogin(teacher,inputPass)
			.then((QuerySnapshot docs) {
			try {
				incoming = Teacher.fromMapObject(docs.documents[0].data);
				incoming.documentId = docs.documents[0].documentID;
				teacher = incoming;
				if(teacher.verify==404)
					Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => AdminDashboard()), (Route<dynamic> route) => false);
				else
					Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => Dashboard(teacher)), (Route<dynamic> route) => false);

			}
			catch(e){
				toast('Wrong credentials');
				print(e);
			}
		});
		return false;
	}

	//This function is for sign up
	static Future<bool> signUp(Teacher teacher,File _image) async {
		int length=0;

		//checking if user already exists
		await Firestore.instance.collection('teach').where('teacherId',isEqualTo: teacher.teacherId).getDocuments().then((QuerySnapshot docs){
			length=docs.documents.length;
		});
		if(length>0) {
			toast('User already exists. Please login');
			return false;
		}
		teacher.pass=await compute(Password.getHash,teacher.pass);
		await uploadPic(teacher,_image);
		await Firestore.instance.collection('teach').add(teacher.toMap());
		return true;
	}

	static Future<bool> profileUpdate(Teacher teacher, File _image, bool newPassword) async {
		if(newPassword) {
			await Firestore.instance.collection('teach').document(teacher.documentId).updateData({'name': teacher.name, 'pass': teacher.pass, 'email': teacher.email, 'mobile': teacher.mobile});
		}
		else
			await Firestore.instance.collection('teach').document(teacher.documentId).updateData({'name': teacher.name, 'email': teacher.email, 'mobile': teacher.mobile});

		if(_image!=null)
			await uploadPic(teacher, _image);
		return true;
	}
	
	static Future<bool> createNewClass(Teaching subject) async {
		int length = 0;
		
		await Firestore.instance.collection('teach').document(subject.teacherDocumentId).collection('subject').where('subjectId', isEqualTo: subject.subjectId).where('classId', isEqualTo: subject.classId).getDocuments().then((QuerySnapshot docs) {
			length=docs.documents.length;
		});
		if(length > 0) {
			toast('Class already exists.');
			return false;
		}
		await Firestore.instance.collection('teach').document(subject.teacherDocumentId).collection('subject').add(subject.toMap());
		return true;
	}
	
	static Future<bool> createTime(Teaching teaching, Timings timings) async {
		int length = 0;
		await Firestore.instance.collection('teach').document(teaching.teacherDocumentId).collection('subject').document(teaching.documentId).collection('timings').where('day', isEqualTo: timings.day).where('duration', isEqualTo: timings.duration).where('start', isEqualTo: timings.start).getDocuments().then((QuerySnapshot docs) {
			length = docs.documents.length;
		});
		if(length > 0) {
			toast('Already Exists.');
			return false;
		}
		await Firestore.instance.collection('teach').document(teaching.teacherDocumentId).collection('subject').document(teaching.documentId).collection('timings').add(timings.toMap());
		return true;
	}

	static Future<bool> createExtraClass(Teaching teaching, Timings timings, String date) async {
		int length = 0;
		await Firestore.instance.collection('teach').document(teaching.teacherDocumentId).collection('subject').document(teaching.documentId).collection('extraClass').where('date', isEqualTo: date).where('duration', isEqualTo: timings.duration).where('start', isEqualTo: timings.start).getDocuments().then((QuerySnapshot docs) {
			length = docs.documents.length;
		});
		if(length > 0) {
			toast('Already Exists.');
			return false;
		}
		var toSend = timings.toMap();
		toSend['date'] = date;
		toSend.remove('day');
		await Firestore.instance.collection('teach').document(teaching.teacherDocumentId).collection('subject').document(teaching.documentId).collection('extraClass').add(toSend);
		return true;
	}

	static Future uploadPic(Teacher student,File _image) async {
		String fileName = student.teacherId;
		StorageReference firebaseStorageRef = FirebaseStorage.instance.ref().child(fileName);
		StorageUploadTask uploadTask = firebaseStorageRef.putFile(_image);
		StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;
	}

}