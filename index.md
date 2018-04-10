---
layout: page
title: "Compiler Construction – CSE 131 S18"
doodle: "/doodle.png"
---

# Compiler Construction

<p>
<a href="https://jpolitz.github.io">Joe Gibbs Politz</a> (Instructor)
</p>

<p>
<a href="#basics">Basics</a> -
<a href="#schedule">Schedule</a> -
<a href="#staff">Staff &amp; Resources</a> -
<a href="#grading">Grading</a> -
<a href="#policies">Policies</a>
</p>

In this course, we'll explore the implementation of **compilers**: programs that
transform source programs into other useful, executable forms. This will
include understanding syntax and its structure, checking for and representing
errors in programs, writing programs that generate code, and the interaction
of generated code with a runtime system.

We will explore these topics interactively in lecure, you will implement
an increasingly sophisticated series of compilers throughout the course to
learn how different language features are compiled, and you will think
through design challenges based on what you learn from implementation.

This web page serves as the main source of announcements and resources for the
course, as well as the syllabus.

<a id="basics">
## Basics

- Lecture: Center 109, 9am MWF
- Discussion: Center 119, 12am F
- **Midterm**: May 4, Center 109, 9am (normal class time)
- **Final**: June 13, TBA, 8am

- Podcasts: <a href="https://podcast.ucsd.edu/podcasts/default.aspx?PodcastId=4931">https://podcast.ucsd.edu/podcasts/default.aspx?PodcastId=4931</a>
- Piazza: <a href="https://piazza.com/class/jfh8ukqgp5h521">https://piazza.com/class/jfh8ukqgp5h521</a>
- Gradescope: <a href="https://www.gradescope.com">https://www.gradescope.com</a> will be used for submissions (instructions will accompany the first programming assignment)
- Textbook/readings: There's no official textbook, but I'll link to different
  online resources for you to read to supplement lecture. Versions of this
  course have been taught at several universities, so sometimes I'll link to
  those instructor's materials, as well.

<a id="schedule">
## Schedule

The schedule below outlines topics, due dates, and links to assignments. In a
typical week, by *Monday before class* all due dates, readings, and notable
events in the course until the following week will be posted here. So if you
check the schedule at the beginning of the week, you'll know when all reading
quizzes, programming assignments, etc. will be due. We will often have the
schedule confirmed more than a week out, but we'll always be at least a week
ahead. The schedule of lecture topics might change slightly, but I post a
general plan so you can know roughly where we are headed.

(The first week is an exception; we'll get everything you need for the first
week out by Tuesday evening.)

<iframe width="125%" height="500px" src="https://docs.google.com/spreadsheets/d/e/2PACX-1vRDuKr9zmldJrL_Xlp0YL75rpd29kzFu7e225l4Yu4s0pEECV5HTv5F68rljHVXMQ6uu62Hz-by2t0J/pubhtml?gid=1920614952&amp;single=true&amp;widget=true&amp;headers=false"></iframe>

<a id="staff">
## Staff & Resources

### Office Hours
Office hours are subjected to change each week, so please check the calendar
before you come. When you come to the office hour, we may ask you to put your
name in the queue using the whiteboard. We won't use Autograder for this 
course, because we want to encourage you to discuss with each other and ask 
questions without code in front of us. That said, for open collaboration 
assignments, we will be happy to help your code if you need it.

<iframe width="125%" height="500px" src="https://calendar.google.com/calendar/embed?src=ahe9u9otkp3ia0vtjsinpb7id4%40group.calendar.google.com&mode=week"></iframe>

### Useful Resources

- [OCaml Website](http://ocaml.org/)
- [List of OCaml Tutorials](http://ocaml.org/learn/tutorials/)
- [OCaml Tutorial](http://mirror.ocamlcore.org/ocaml-tutorial.org/)
- [x86 Assembly Guide](http://www.cs.virginia.edu/~evans/cs216/guides/x86.html)
- [An Incremental Approach to Compiler Construction](http://scheme2006.cs.uchicago.edu/11-ghuloum.pdf)

<a id="grading">
## Grading

Your grade will be calculated from:

- 5% participation via clickers
  - Each week both lecture and discussion will have clicker questions. You get
    credit for each session where you answer at least half of the questions.
  - Discussion attendance is not mandatory to get full clicker credit
  - Credit is awarded proportionally to the number of total lectures with
    clicker questions (usually around 25), with 4 allowed absences
- 5% review quizzes
  - Each week there will be an online review quiz, you get full review quiz
    credit for getting at least half the questions right
- 40% programming assignments (7-9 total)
- 20% take home written work
- 30% exams
  - 10% a midterm exam, in class
  - 20% final exam
    - You must score over 50% on the final exam to pass the course
    - If you score higher on the final exam than on the midterm (including 0's on
      the midterm), the final applies at 30%
    - There are no make-up midterms; if you do not take the midterm, you get the
      same score on the midterm as you get on the final

<a id="policies">
## Policies

### Late Work

You have a total of 4 extension days that you can apply over the course of the
quarter. Any amount of time (up to 24 hours) past the deadline counts as a full
day. These apply to programming assignments and to take-home work. You cannot
use more than one day on a given assignment.

### Regrades

Mistakes occur in grading. Once grades are posted for an assignment, we will
allow a short period for you to request a fix (announced along with grade
release). If you don't make a request in the given period, the grade you were
initially given is final.

### Exams

You are not allowed any study aids on in-class exams, aside from those
pertaining to university-approved accommodations. References will be provided
along with exams to avoid unnecessary memorization.

You cannot discuss the content of exams with others in the course until grades
have been released for that exam.

### Academic Integrity

There are two types of assignments in this course:

- **Open collaboration** assignments, for which you can talk to anyone else in the
  course, post snippets of code on Piazza, get lots of help from TAs, and
  generally come up with solutions collaboratively. TAs will be happy to look
  at your code and suggest fixes, along with explaining them. There are a few
  restrictions:
  - Any code that you didn't write must be cited in the README file that goes
    along with your submission
      - **Example:** On an open collaboration assignment, you and another
        student chat online about the solution, you figure out a particular
        helper method together. Your README should say “The FOO function was
        developed in collaboration with Firstname Lastname”
      - **Example:** On an open collaboration assignment, a student posts the
        compilation strategy they used to handle a type of expression you were
        struggling with. Your README should say “I used the code from
        https://piazza.com/class/id-of-post”
  - Anyone you work with in-person must be noted in your README
      - **Example:** You and another student sit next to each other in the lab,
        and point out mistakes and errors to one another as you work through
        the assignment. As a result, your solutions are substantially similar.
        Your README should say “I collaborated with Firstname Lastname to
        develop my solution.”
  - You cannot share an entire repository of code or paste an entire solution
    into Piazza. Keep snippets to reasonable, descriptive chunks of code; think
    a dozen lines or so to get the point across.
  - You still _cannot_ use code that you find online, or get assistance or code
    from students outside of this offering of the class. All the code that is
    handed in should be developed by you or someone in the class.

- **Closed collaboration** assignments, where you cannot collaborate with others.
  You can ask clarification questions as private posts on Piazza or of TAs.
  However, TAs will not look at your code or comment on it. Lab/office hours
  these weeks are for conceptual questions or for questions about past
  assignments only, no code assistance. On these assignments:
    - You cannot look at or use anyone else's code
    - You cannot discuss the assignment with other students
    - You cannot post publicly about the assignment on Piazza (or on social
      media or other forums). Of course, you can still post questions about
      material from lecture on Piazza!
    - All of the examples in the open collaboration section above would be
      academic integrity violations on a closed collaboration assignment

Programming assignments will explicitly list whether they are open or closed
collaboration. There will also be take-home written homeworks, which are always
closed collaboration.

You should be familiar with [the UCSD
guidelines](http://senate.ucsd.edu/Operating-Procedures/Senate-Manual/Appendices/2)
on academic integrity as well.

### Diversity and Inclusion

We are committed to fostering a learning environment for this course that
supports a diversity of thoughts, perspectives and experiences, and respects
your identities (including race, ethnicity, heritage, gender, sex, class,
sexuality, religion, ability, age, educational background, etc.).  Our goal is
to create a diverse and inclusive learning environment where all students feel
comfortable and can thrive.

Our instructional staff will make a concerted effort to be welcoming and
inclusive to the wide diversity of students in this course.  If there is a way
we can make you feel more included please let one of the course staff know,
either in person, via email/discussion board, or even in a note under the door.
Our learning about diverse perspectives and identities is an ongoing process,
and we welcome your perspectives and input.

We also expect that you, as a student in this course, will honor and respect
your classmates, abiding by the UCSD Principles of Community
(https://ucsd.edu/about/principles.html).  Please understand that others’
backgrounds, perspectives and experiences may be different than your own, and
help us to build an environment where everyone is respected and feels
comfortable.

If you experience any sort of harassment or discrimination, please contact the
instructor as soon as possible.   If you prefer to speak with someone outside
of the course, please contact the Office of Prevention of Harassment and
Discrimination: https://ophd.ucsd.edu/.
