# **Advanced Operating Systems Assessment Scripting Solutions**

## **University Data Centre, HPC Scheduler & Exam Submission Automation**

This project showcases three advanced automation scripts written in **Bash** and **Python**. They are designed to tackle real-world system administration problems related to process monitoring, high-performance computing (HPC) job scheduling, and assignment submission validation, ultimately improving system efficiency, resource handling, and security automation.

## **Table of Contents**

* [Project Overview](https://www.google.com/search?q=%23project-overview)  
* [1 University Data Centre Process & Resource Management (Bash)](https://www.google.com/search?q=%231-university-data-centre-process--resource-management-bash)  
* [2 University HPC Job Scheduler System (Bash)](https://www.google.com/search?q=%232-university-hpc-job-scheduler-system-bash)  
* [3 University Examination Submission & Similarity Detection (Bash & Python)](https://www.google.com/search?q=%233-university-examination-submission--similarity-detection-bash--python)  
* [Installation & Usage](https://www.google.com/search?q=%23installation--usage)  
* [Features & Highlights](https://www.google.com/search?q=%23features--highlights)  
* [Testing & Validation](https://www.google.com/search?q=%23testing--validation)

---

## **Project Overview**

This project aims to automate critical server-side tasks within a University environment. By utilizing Bash for system-level interactions and Python for complex data validation, the system ensures that server resources are monitored, computational jobs are fair-shared among users, and academic integrity is maintained through binary file comparison.

### **1 University Data Centre Process & Resource Management (Bash)**

This module focuses on Learning Outcome 2 by automating system health checks. It provides real-time CPU and Memory snapshots and implements a "Safe Kill" feature that prevents the accidental termination of critical system PIDs. Additionally, it automates storage cleanup by archiving large log files.

### **2 University HPC Job Scheduler System (Bash)**

Designed to manage a research job queue, this script implements two core scheduling algorithms:

* **Round Robin:** Uses a 5-second Time Quantum to ensure equitable CPU distribution.  
* **Priority Scheduling:** Hierarchizes tasks based on urgency (1-10) to ensure critical research is processed first.  
  It utilizes file-locking mechanisms to prevent race conditions during queue updates.

### **3 University Examination Submission & Similarity Detection (Bash & Python)**

A high-security submission portal that validates file formats (PDF/DOCX) and sizes. It integrates a Python back-end to perform a binary deep-scan of every upload, detecting if a student attempts to submit a duplicate file under a different name.

---

## **Installation & Usage**

### **Data Centre Monitoring**

To execute the system monitor:

Bash  
chmod \+x system\_monitoring1.sh  
./system\_monitoring1.sh

### **HPC Job Scheduler**

To manage the job queue:

Bash  
chmod \+x job\_scheduler3.sh  
./job\_scheduler3.sh

### **Exam Submission & Similarity Detection**

To run the submission portal and the Python similarity detector:

Bash  
chmod \+x submission\_system4.sh compare\_files2.py  
./submission\_system4.sh

---

## **Features & Highlights**

| Feature | Data Centre Monitor | HPC Scheduler | Exam Submission |
| :---- | :---- | :---- | :---- |
| **File Operations** | Yes | Yes | Yes |
| **Process Protection** | Yes | No | No |
| **Queue Processing** | No | Yes | No |
| **Duplicate Prevention** | No | No | Yes |
| **Logging System** | Yes | Yes | Yes |
| **Similarity Detection** | No | No | Yes |

---

## **Testing & Validation**

### **Testing Overview**

Each script has been rigorously tested to ensure:

* **Resilience:** Using trap to handle SIGINT (Ctrl+C) and clean up lock files.  
* **Integrity:** Preventing special characters from corrupting the .txt database files.  
* **Security:** Enforcing **Read-Only (400)** permissions on all successful submissions.

---

## **Author**

**Álvaro Fidalgo Martinez-Merello**

Student ID: 100181642

Canterbury Christ Church University

