# Record_system
A record system in x86_32 Assembly that helps administrators to keep track of their computers.

# Functions
It stores the following information about computers:
 - Computer Name
 - IP Address
 - OS (Linux, Windows, or Mac OSX)
 - User ID of main user
 - Date of Purchase

It also stores the following information about people:
 - Surname
 - First Name
 - User ID
 - Email Address 
 - Department (Development, IT Support, Finance, or HR)

# Operations
The system also performs the following operations:
 - Add/Delete User
 - Add/Delete Computer
 - Search for computer given a computer name
 - Search for user given a user ID
 - List all users
 - List all computers 

# Assumptions
 - First names and surnames, all have a maximum size of 64 chars 
 - Computer names are unique, and are in the form of cXXXXXXX where XXXXXXX is any 7 digit number 
 - User IDs are unique, and are in the form of pXXXXXXX where XXXXXXX is any 7 digit number 
 - Email addresses are in the form @helpdesk.co.uk 
 - There is a maximum of 100 users and 500 computers on the system 
