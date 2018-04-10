import os

import glob

path = 'ucsd-cse131-s18.github.io/lectures/'
lecture_path='./lectures'
url_protocol='https://'

master = open('README.md','w')
master.write('https://ucsd-cse131-s18.github.io\n\nLecture notes links:\n\n')
os.chdir(lecture_path)


lectures = glob.glob('./*')


for lecture in sorted(lectures):

  os.chdir(lecture)

  current = lecture.split('/')[-1]
  
  files = glob.glob('./*')

  for f in sorted(files):
    name=f.split('.')
    if name[-1] == 'html':
      url = url_protocol+path+current+f[1:]
      master.write(url+'\n\n')

  os.chdir('..')

master.close()
