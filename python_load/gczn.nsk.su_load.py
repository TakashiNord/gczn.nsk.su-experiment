#!/usr/bin/env python
# -*- coding: utf-8 -*-
#-------------------------------------------------------------------------------
import os
import time
import datetime
import threading
import string
import re
# парсер командной строки
import sys
import random
import hashlib
import shutil
import urllib2
#from urllib import urlopen
import xml.etree.ElementTree as ET
# Опрос источников - асинхронно (с использованием библиотеки gevent). 
import gevent
from gevent import monkey

""" Источники - название источника введено, для предварительного запроса в БД"""
urls = {
    'http://www.gczn.nsk.su//?option=com_helloworld&template=gczn_vac&vacancy='
}


def getNewSID(tag):
    ''' Build a new session ID '''
    t1 = time.time()
    time.sleep(random.random())
    t2 = time.time()
    base = hashlib.md5(tag + str(t1+t2)).hexdigest()
    return '_'.join((tag, base))


def XMLParcerDB( url , orig, dest ):
    """ Возвращаем значения """
    #===================================
    ddate="" # дата
    drate=-1 # курс
    dname="" # название Источника
    #===================================
    #print 'Starting %s' % url
    data = urllib2.urlopen(url).read()
    name1 = os.path.basename(url)
    name2 = os.path.splitext(name1)
    #print '%s \n%s \n%s bytes\n%r' % (url, name1, len(data), data[:100])
    filename1 = getNewSID(name2[0]) + name2[1] # создаем файл под случайным именем для отладки os.tempname
    # удалить временный файл
    filename2 = os.path.join(os.getcwd(), filename1)
    if os.path.exists(filename2)==True : os.remove(filename2)
    file_object = open(filename2, 'w')
    file_object.write(data)
    file_object.close( )
    tn2 = datetime.datetime.now()
    if name2[1]=='.asp' :
        tree = ET.parse(filename2)
        root = tree.getroot()
        #print "tag=%s  atr=%s" , root.tag, root.attrib
        ddate = root.get('Date')
        dtobj=datetime.datetime(*reversed(map(int,ddate.split('.'))))
        ddate = dtobj.strftime("%Y-%m-%d") + " " + tn2.strftime("%H:%M:%S")
        dname = root.get('name')
        for child in root:
            if child.find('CharCode').text==orig :
                drate = child.find('Value').text
                #print "value=%s" % child.find('Value').text
                break ;
    if name2[1]=='.xml' :
        tree = ET.parse(filename2)
        root = tree.getroot()
        #for elem in tree.iter():
            #print elem.tag, elem.attrib
        #Create an iterator
        iter = root.getiterator()
        #Iterate
        for element in iter:
            ##print "Element:", element.tag
            #Text that precedes all child elements (may be None)
            if element.text:
                text = element.text
                #if string.find(element.tag, "name")>0 : dname = repr(text)
                if re.findall("name", element.tag, re.IGNORECASE) : dname = repr(text)
            if element.keys():
                ##print "\tAttributes:"
                fl=0
                for name, value in element.items():
                    if name=='time' : ddate = value
                    if name=='currency' :
                        if value==dest : fl=1
                    if fl==1 :
                        if name=='rate' : drate = value
                    #print "\t\tName: '%s', Value: '%s'"%(name, value)
        if (ddate!="") : ddate = ddate + " " + tn2.strftime("%H:%M:%S")
    if (ddate=="") : ddate = tn2.strftime("%Y-%m-%d %H:%M:%S")
    dn1=dname.replace("'","")
    dname=dn1.encode('utf8')
    return(dname,ddate,drate)


def HTMLParcerDB( url ):
    """ Возвращаем значения """
    #===================================
    #===================================
    #print 'Starting %s' % url
    data = urllib2.urlopen(url).read()
    name1 = os.path.basename(url)
    name2 = os.path.splitext("html")
    #print '%s \n%s \n%s bytes\n%r' % (url, name1, len(data), data[:100])
    filename1 = getNewSID(name2[0]) + '.txt' # создаем файл под случайным именем для отладки os.tempname
    # удалить временный файл
    filename2 = os.path.join(os.getcwd(), filename1)
    if os.path.exists(filename2)==True : os.remove(filename2)
    file_object = open(filename2, 'w')
    #file_object.write(data)
    #file_object.close( )
    #
    r0 = re.compile('<table.*/table>',re.MULTILINE|re.UNICODE|re.IGNORECASE|re.DOTALL)
    line = r0.search( data )
    #print line
    if line:
        #print 'Match found: ', line.group()
        line = line.group()
        # удаляем все комментарии
        rs1 = '<!--.*-->|<b>|</b>|<small>|</small>|&nbsp;|class=|\"clear\"|\"full_vac\"|\"vac_general\"|\"vac_header\"|\"vac_trebovanie|vac_after_header\"|\"vac_podrobnee|vac_after_header\"|\"vac_predpriyatie|style=\"display:block;\"';
        r1 = re.compile(rs1,re.MULTILINE|re.UNICODE|re.IGNORECASE)
        line = re.sub(r1, '', line)
    if line: file_object.write(line)
    file_object.close( )
    return(0)



def MainSQLHTML( url, n ):
    """  """
    #===================================================
    #
    #===================================================
    s1 = url + str(n)
    HTMLParcerDB(s1);
    #===================================================
    return(0)


def Main():
    """Главная функция"""
    #===================================================
    now_date = datetime.date.today() # Текущая дата (без времени)
    now_time = datetime.datetime.now() # Текущая дата со временем
    smsg = "Script time run= " + now_time.strftime("%Y-%m-%d %H:%M:%S")
    print (smsg)
    print ""
    num = 1496 ;
    #===================================================
    # 1 - запускаем потоки-события
    #===================================================
    ### запуск без потоков
    #for url in urls:
    #    print url, num
    #    MainSQLHTML(url, num )
    #    ###
    for num in range(4700):
        jobs = [gevent.spawn(MainSQLHTML, url, num ) for url in urls ]
        gevent.joinall(jobs)
    #===================================================
    return(0)


if __name__ == '__main__':
    Main()



