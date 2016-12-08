#!/usr/bin/python

from azure.storage import *
import base64
import zipfile
import os.path
import os
import boto
import sys
import shutil

pref = str(sys.argv[1])
print(pref)
chunk_size = 4 * 1024

import boto

def store_private_data(bucket_name, key_name, path_to_file):
	s3 = boto.connect_s3()
	bucket = s3.lookup(bucket_name)
	key = bucket.new_key(key_name)
	data = 'wav from azure'
	key.set_contents_from_string(data)
	stored_key = bucket.lookup(key_name)
	stored_data = stored_key.get_contents_as_string()
	assert stored_data == data
	key.set_contents_from_filename(path_to_file)
	return key


def download(blob_service, container_name, blob_name, file_path):
    props = blob_service.get_blob_properties(container_name, blob_name)
    blob_size = int(props['content-length'])

    index = 0
    with open(file_path, 'wb') as f:
        while index < blob_size:
        #    chunk_range = 'bytes={}-{}'.format(index, index + chunk_size - 1)
           # data = blob_service.get_blob(container_name, blob_name, x_ms_range=chunk_range)
            data = blob_service.get_blob(container_name, blob_name)
            length = len(data)
            index += length
            if length > 0:
                f.write(data)
            #    if length < chunk_size:
            #        break
            else:
                break

def uploads3(path, blobname):
	zfile = zipfile.ZipFile(path)
	spath = "/tmp/" + "azure_wav/" + blobname
	os.makedirs(spath)
	for name in zfile.namelist():
		(dirname, filename) = os.path.split(name)
		print(dirname, filename)
		if filename == '':
			if not os.path.exists(dirname):
				os.mkdir(dirname)
		else:
			fd = open(name, 'w')
			fd.write(zfile.read(name))
			fd.close()
		shutil.copy(name, spath)
#		localpath = name
#		spath = "azure_wav/" + pref  + '/' +  blobname + '/' + filename
#		print(spath, localpath, filename)
#		key = store_private_data("backup_chrys", spath, localpath)
#		if(key) :
#			os.remove(localpath)

	zfile.close()



blob_service = BlobService(account_name='', account_key='')

marker = 'en-US_' + pref
print(marker)
blobs = blob_service.list_blobs('soundlog', marker, None, 2)
for blob in blobs:
	print(blob.name)
	path = '/tmp/' + str(blob.name)
	print( path)
	download(blob_service, 'soundlog', blob.name, path)
	uploads3(path, blob.name)

#print('-----next marker------' + blobs.next_marker)

count = 2
#marker = 'en-US' + pref
#while str(blobs.next_marker) :
#	print('-----next marker------' + blobs.next_marker)
#	blobs = blob_service.list_blobs('soundlog', marker, blobs.next_marker, 5000)
#	for blob in blobs:
#		print(blob.name)
#		path = '/tmp/' + str(blob.name)
#		download(blob_service, 'soundlog', blob.name, path)
#		uploads3(path, blob.name)
#		count = count + 1
#		print(count)

