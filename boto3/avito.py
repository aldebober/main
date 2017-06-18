#!/usr/bin/env python
# -*- coding: utf-8 -*-
from urllib2 import urlopen
from BeautifulSoup import BeautifulSoup
import requests
import re
import smtplib
import sys
reload(sys)
sys.setdefaultencoding('utf-8')
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

rs = re.compile('(\d+\ \d+)(\&nbsp;)', re.I)
ids = []
result = []


def get_html(url):
    response = requests.get(url)
    if response.status_code == requests.codes.ok:
        soup = BeautifulSoup(response.text)
    return soup


def get_links(soup):
    collect = soup.find('div', 'js-catalog_before-ads')
    links = collect.findAll('a')
    links_array = []
    for link in links:
        if 'sankt-peterburg' not in link.get('href'):
            continue
        if ((('http://avito.ru' + link.get('href')) not in (links_array)) &
            (link.get('href').find('favorites') == -1)):
            links_array.append('http://avito.ru' + link.get('href'))
    return links_array


def get_values(collect, link):
    flat = {}
    imgs = []
    metro_name = None
    dist = '0 m'
    mdist = []

    pr1 = collect.find('span', 'price-value-string').contents[0]
    p1 = rs.search(pr1)
    price = int(p1.group(1).replace(' ', ''))
    preprice = collect.find('div', 'item-price-sub-price')
    zalog = preprice.contents[0].rstrip('&nbsp;')
    addr = collect.find('span', 'item-map-address').contents[0]
    try:
        address = addr.span.contents[0].strip()
    except:
        address = None
    pics = collect.findAll('div', 'gallery-img-wrapper')
    for img in pics:
        uri = img.find('div', 'gallery-img-frame')['data-url']
        imgs.append('https' + uri)
    metros = collect.findAll('span', 'item-map-metro')
    for metro in metros:
        if metro and len(metro.contents) > 1:
            name, d = metro.contents[2].split('(')
            metro_name = name.strip()
            dist = d.replace('&nbsp;', ' ').strip().rstrip(')')
            mdist.append(metro_name + dist)
#            print metro_name, dist
    id_flat = collect.find('div', 'b-search-map expanded')['data-item-id']
    descr = collect.find('div', 'item-description')
    if len(preprice.contents) <= 3:
        ids.append(id_flat)
        flat = {
            "flat_id": id_flat,
            "price": price,
            "description": descr.p.contents[0],
            "zalog": zalog,
            "url": link,
            "metro": mdist,
            "imgs_link": imgs
        }
#    else:
#        print preprice.contents[2]
    result.append(flat)

def read_f(filename):
    with open(filename, 'r') as f:
        read_data = f.read().splitlines()
    f.close()
    return read_data

def write_f(filename, array):
    with open(filename, 'w') as f:
        f.write('\n'.join(array))
    f.close

def check_new(array):
    old_ids = read_f('/tmp/avito_ids')
    diff_list = list(set(array).symmetric_difference(set(old_ids)))
    if diff_list:
        write_f('/tmp/avito_ids', array)
        return diff_list

def mailto(new_ids):
   me = "my@email.com"
   you = "yourixadm@gmail.com"
   msg = MIMEMultipart('alternative')
   msg['Subject'] = "Avito"
   msg['From'] = me
   msg['To'] = you
   for flat in result:
       if flat and flat["flat_id"] in new_ids:
           #print 'flat["description"] + '\n' + '\n'.join(flat["metro"]) + '\n'.join(flat["imgs_link"]) + flat["price"] + flat["zalog"] + flat["url"]'
           text = str(flat["description"]) + '\n' + '\n'.join(flat["metro"]) + '\n' + str(flat["price"])  + '\n' + flat["url"] 
           print text
           part = MIMEText(text.encode('utf-8'), 'text')
           msg.attach(part)
   s = smtplib.SMTP('localhost')
   s.sendmail(me, you, msg.as_string())
   s.quit()


collect = get_html(
    'https://www.avito.ru/sankt-peterburg/kvartiry/sdam/na_dlitelnyy_srok/1-komnatnye?metro=156-158-163-164-178-185-199-201-202-203-205-206-1015-1016-1017-2122&f=550_5702-5703&pmax=26000'
)
links_array = get_links(collect)
i = 0
while i < len(links_array):
#    print links_array[i]
    collect = get_html(links_array[i])
    get_values(collect, links_array[i])
    i += 1

if ids:
    new_ids = check_new(ids)
if new_ids:
    print new_ids
    mailto(new_ids)
