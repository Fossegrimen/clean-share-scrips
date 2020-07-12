
import json
import os
import re
import subprocess
import sys
import urllib.request

from os.path import normpath, basename
from time import sleep

OPTION_USING_REGEX = True
OPTION_CASE_INSENSITIVE_DIR_MATCHING = True

class Logger:
    rels_log_file       = None
    rels_completed_file = None
    rels_missing_file   = None
    rels_no_scene_file  = None

    rels_log_data       = None
    rels_completed_data = None
    rels_missing_data   = None
    rels_no_scene_data  = None

    rels_log_temp_data  = []

    def __init__(self, save_path):
        self.rels_log_file       = self.intialize_log_file(save_path, 'rels_log')
        self.rels_completed_file = self.intialize_log_file(save_path, 'rels_completed')
        self.rels_missing_file   = self.intialize_log_file(save_path, 'rels_missing')
        self.rels_no_scene_file  = self.intialize_log_file(save_path, 'rels_no_scene')

        self.rels_log_data       = self.rels_log_file.read().splitlines()
        self.rels_completed_data = self.rels_completed_file.read().splitlines()
        self.rels_missing_data   = self.rels_missing_file.read().splitlines()
        self.rels_no_scene_data  = self.rels_no_scene_file.read().splitlines()

    def __del__(self):
        self.rels_log_file.close()
        self.rels_completed_file.close()
        self.rels_missing_file.close()
        self.rels_no_scene_file.close()

    def intialize_log_file(self, save_path, log_name):
        save_path = os.path.join(os.getcwd(), save_path)

        if not os.path.exists(save_path):
            os.makedirs(save_path)

        if os.path.exists(os.path.join(save_path, log_name)):
            return open(os.path.join(save_path, log_name), 'r+')
        else:
            return open(os.path.join(save_path, log_name), 'w+')

    def add_rels_log(self, line):
        self.rels_log_temp_data.append(line)

    def write_rels_log(self):
        if len(self.rels_log_temp_data) > 4:
            for line in self.rels_log_temp_data:
                self.rels_log_file.write(line)

            self.rels_log_file.write('\n')
        self.rels_log_temp_data.clear()

    def write_rels_completed(self, line):
        if len(self.rels_log_temp_data) == 4:
            self.rels_completed_file.write(line)

    def write_rels_missing(self, line):
        self.rels_missing_file.write(line)

    def write_rels_no_scene(self, line):
        self.rels_no_scene_file.write(line)

def download_file(release_path, release_name, file):
    if not (file.lower().endswith('.nfo') or file.lower().endswith('.sfv') or file.lower().endswith('.jpg')):
        return

    save_path     = os.path.join(os.getcwd(), 'logs', release_path.strip('/'))
    save_filename = file

    index = file.rfind('/')

    if index >= 0:
      save_path     = os.path.join(save_path, file[0:index].strip('/'))
      save_filename = file[index + 1:]

    if not os.path.exists(save_path):
        os.makedirs(save_path)

    save_path = os.path.join(save_path, save_filename)

    if not os.path.exists(save_path):
        sleep(1)

        try:
            urllib.request.urlretrieve('https://www.srrdb.com/download/file/' + release_name + '/' + file, save_path)
        except Exception as e:
            print(e)

def download_data(release_path, release_name, files, logger):
    try:
        sleep(1)

        url  = urllib.request.urlopen('https://www.srrdb.com/api/details/' + release_name, timeout=10)
        data = json.loads(url.read().decode())

        return data
    except:
        try:
            url  = urllib.request.urlopen('https://predb.ovh/api/v1/?q=' + release_name, timeout=10)
            data = json.loads(url.read().decode())

            if data['status'] == 'success' and data['data']['rowCount'] > 0:
                logger.write_rels_missing(release_name + '\n')
                return None
        except:
            pass

    logger.write_rels_no_scene(release_name + '\n')
    return None

def get_filenames(data):
    files = list()

    for info in data['files']:
        if len(info['name']) > 1:
            files.append(info['name'])

    files.sort()

    return files

def count_files_in_directory(files, dir_name):
    amount = 0

    for file in files:
        if file.lower().startswith(dir_name.lower() + '/'):
            amount = amount + 1

    return amount

def find_file(files_external, file):
    for file_ in files_external:
        if file_ == file:
            return True

    return False

def get_lower_case_dir(file):
    index = file.find('/')

    if index >= 0:
      return file[0:index].lower() + file[index:]
    else:
      return file

def get_crc(file, data):
    for info in data['files']:
        if file == info['name']:
            return info['crc']
        elif OPTION_CASE_INSENSITIVE_DIR_MATCHING:
            file_ = get_lower_case_dir(file)
            name_ = get_lower_case_dir(info['name'])

            if file_ == name_:
                return info['crc']

    return ''

def fix_crc(file, data, new_file):
    for info in data['files']:
        if file == info['name']:
            info['name'] = new_file
            return

def is_release_dir(release_name, files):
    if not re.match('.+-.+', release_name):
       return False

    for file in files:
        if file.find('/') != -1:
            continue;
        elif re.match('.+\.(ace|flac|m3u|mp3|(r|s)?[0-9]+|rar|sfv|zip)$', file, re.IGNORECASE):
            return True

    return False

def get_list_of_files(dir_path):
    list_of_files = os.listdir(dir_path)
    all_files = list()

    for entry in list_of_files:
        full_path = os.path.join(dir_path, entry)

        if os.path.isdir(full_path):
            all_files = all_files + get_list_of_files(full_path)
        else:
            all_files.append(full_path)

    all_files.sort()

    return all_files

def verify_release(release_path, release_name, files, data, logger):
    logger.add_rels_log('----------------------------------------------------------------\n')
    logger.add_rels_log(release_path + '\n')
    logger.add_rels_log(release_name + '\n')
    logger.add_rels_log('----------------------------------------------------------------\n')

    if release_name != data['name']:
        logger.add_rels_log('Release name mismatch' + '\n')
        logger.add_rels_log('Should be renamed to:\t' + data['name'] + '\n')

    if len(data['files']) == 1:
        if not re.match('.+FiX.+', release_name, re.IGNORECASE):
            logger.write_rels_missing(release_name + '\n')
            logger.write_rels_log()
            return
    elif len(data['files']) == 0:
        logger.write_rels_missing(release_name + '\n')
        logger.write_rels_log()
        return

    files_internal = files

    for file in files_internal:
        if not re.match('.+\.(ace|avi|flac|jpg|m3u|mkv|mp3|mp4|mpg|nfo|(r|s)?[0-9]+|rar|sfv|zip)$', file, re.IGNORECASE):
            print('ILLEGAL_INTERNAL_FILE: ' + file)
            logger.add_rels_log('ILLEGAL_INTERNAL_FILE:\t' + file + '\n')
        elif re.match('.+(Bluray|DVDR|DVDRip|HDDVD|HDTV|PDTV|x264|XViD).+', file, re.IGNORECASE):
            if not re.match('.+\/.+', file, re.IGNORECASE):
                if not re.match('.+\.(nfo|(r|s)?[0-9]+|rar|sfv)$', file, re.IGNORECASE):
                    logger.add_rels_log('ILLEGAL_INTERNAL_FILE:\t' + file + '\n')

    files_external = get_filenames(data)
    files_external_temp = files_external.copy()

    for file in files_external_temp:
        if not re.match('.+\.(ace|avi|flac|jpg|m3u|mkv|mp3|mp4|mpg|nfo|(r|s)?[0-9]+|rar|sfv|zip)$', file, re.IGNORECASE):
            print('ILLEGAL_EXTERNAL_FILE: ' + file)
            files_external.remove(file)
        elif re.match('^Proof\/.+', file, re.IGNORECASE):
            if not re.match('.+\.jpg$', file, re.IGNORECASE):
                files_external.remove(file)
        elif re.match('^Sample\/.+', file, re.IGNORECASE):
            if not re.match('.+\.(avi|mkv|mp4|mpg)$', file, re.IGNORECASE):
                files_external.remove(file)
        elif re.match('^Subs\/.+', file, re.IGNORECASE):
            if not re.match('.+\.((r|s)?[0-9]+|rar|sfv)$', file, re.IGNORECASE):
                files_external.remove(file)

    additional_internal_files = list(set(files_internal) - set(files_external))
    additional_external_files = list(set(files_external) - set(files_internal))

    if additional_internal_files:
        for file in additional_internal_files:
            if re.match('^Proof\/.+\.jpg$', file, re.IGNORECASE):
                if find_file(files_external, file[6:]):
                    additional_external_files.remove(file[6:])
                    fix_crc(file[6:], data, file)
                    continue
                elif count_files_in_directory(files_internal, 'Proof') == 1 and \
                     count_files_in_directory(files_external, 'Proof') == 0:
                     files.remove(file)
                     continue
            elif re.match('^Sample\/.+\.(avi|mkv|mp4|mpg)$', file, re.IGNORECASE):
                if find_file(files_external, file[7:]):
                    additional_external_files.remove(file[7:])
                    fix_crc(file[7:], data, file)
                    continue
                elif count_files_in_directory(files_internal, 'Sample') == 1 and \
                     count_files_in_directory(files_external, 'Sample') == 0:
                     files.remove(file)
                     continue
            elif re.match('^Subs\/.+\.((r|s)?[0-9]+|rar|sfv)$', file, re.IGNORECASE):
                if find_file(files_external, file[5:]):
                    additional_external_files.remove(file[5:])
                    fix_crc(file[5:], data, file)
                    continue
                elif count_files_in_directory(files_external, 'Subs') <= 1:
                    files.remove(file)
                    continue

            files.remove(file)
            logger.add_rels_log('EXTRA_INTERNAL_FILE:\t' + file + '\n')

    if additional_external_files:
        for file in additional_external_files:
            if re.match('^Proof\/.+', file, re.IGNORECASE) and \
               not re.match('.+\.jpg$', file, re.IGNORECASE):
                    continue
            elif re.match('^Sample\/.+', file, re.IGNORECASE) and \
               not re.match('.+\.(avi|mkv|mp4|mpg)$', file, re.IGNORECASE):
                    continue
            elif re.match('^Subs\/.+', file, re.IGNORECASE) and \
               not re.match('.+\.((r|s)?[0-9]+|rar|sfv)$', file, re.IGNORECASE):
                    continue

            download_file(release_path, release_name, file)
            logger.add_rels_log('EXTRA_EXTERNAL_FILE:\t' + file + '\n')

    for file in files:
        if OPTION_USING_REGEX:
            if not re.match('.+\.(avi|jpg|m3u|mkv|mp4|mpg|nfo|sfv)$', file, re.IGNORECASE):
                continue
            elif not file.startswith('Subs/'):
                continue

        process = subprocess.Popen(['/usr/local/bin/rhash', '--printf=%C', release_path + '/' + file], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = process.communicate()

        crc_internal = stdout.decode('UTF-8')
        crc_external = get_crc(file, data)

        if (crc_internal != crc_external):
            download_file(release_path, release_name, file)
            logger.add_rels_log('CRC mismatch:\t' + crc_internal + ' ' + crc_external + '\t' + file + '\n')

    logger.write_rels_completed(release_name + '\n')
    logger.write_rels_log()

def scan_dir(dir_path, logger):
    subfolders = [f.path for f in os.scandir(dir_path) if f.is_dir()]

    for release_path in list(subfolders):
        release_name = basename(normpath(release_path))

        if release_name in logger.rels_completed_data:
            continue
        elif release_name in logger.rels_missing_data:
            continue
        elif release_name in logger.rels_no_scene_data:
            continue

        scan_dir(release_path, logger)

        files = [file.replace(release_path + '/', '') for file in get_list_of_files(release_path)]

        if not is_release_dir(release_name, files):
            continue

        data = download_data(release_path, release_name, files, logger)

        if data:
            verify_release(release_path, release_name, files, data, logger)

if len(sys.argv) != 2:
    sys.exit("Missing argument")

scan_dir(str(sys.argv[1]), Logger(os.path.join(os.getcwd(), 'logs', str(sys.argv[1]).strip('/'))))
