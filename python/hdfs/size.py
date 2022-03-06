import subprocess
import math

def run_cmd(args_list):
    """
    run linux commands
    """
    proc = subprocess.Popen(args_list, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    s_output, s_err = proc.communicate()
    s_return =  proc.returncode
    return s_return, s_output, s_err

def convert_size(size):
    if (float(size) == 0):
        return '0B'
    size_name = ("B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB")
    i = int(math.floor(math.log(float(size),1024)))
    p = math.pow(1024,i)
    s = round(float(size)/p,2)
    return '%s %s' % (s,size_name[i])

def print_size(path):

    (ret, out, err) = run_cmd(['hdfs', 'dfs', '-count', path])
    lines = out.decode().split('\n')

    print('-'.ljust(148,'-'))
    print('|' + 'Path'.ljust(65) + ' | ' + 'DIR Count'.rjust(10) + ' | ' + \
                'File Count'.rjust(10) + ' | ' + 'Size (Bytes)'.rjust(15) + ' | ' + \
                'Size (GB/TB)'.rjust(15) + ' | ' + 'File Size'.rjust(15) + ' | ')
    print('-'.ljust(148,'-'))

    result=[]
    for idx, val in enumerate(lines):
        columns = ' '.join(val.split()).split(' ')
        if columns[0]:
            directory_size = convert_size(columns[2])
            file_size=0
            if float(columns[1]) > 0:
                file_size = convert_size(float(columns[2])/float(columns[1]))
                result.append({"path":columns[3],"dir_count":columns[0],"file_count":columns[1],"size_bytes":int(columns[2]),\
                               "directory_size":directory_size,"file_size":file_size})

    sorted_result = sorted(result, key=lambda x: x['size_bytes'],reverse=True)

    for i in sorted_result:
        print('|' + i['path'].ljust(65) + ' | ' + i['dir_count'].rjust(10) + ' | ' + \
                    i['file_count'].rjust(10) + ' | ' + str(i['size_bytes']).rjust(15) + ' | ' + \
                    i['directory_size'].rjust(15) + ' | ' + str(i['file_size']).rjust(15) + ' | ')

def main():
    (ret, out, err) = run_cmd(['hdfs', 'dfs', '-count', '-q', '/projects/evaluate'])
    columns = ' '.join(out.decode().split()).split(' ')
    if columns[0]:
        print('PATH                   : ' + columns[7])
        print('QUOTA                  : ' + columns[0])
        print('REMAINING_QUATA        : ' + str(columns[1]) + '(' + str(round((float(columns[1])/float(columns[0]))*100,2)) + '%)' )
        print('SPACE_QUOTA            : ' + convert_size(columns[2]))
        print('REMAINING_SPACE_QUOTA  : ' + convert_size(columns[3]) + ' (' + str(round((float(columns[3])/float(columns[2]))*100,2)) + '%)' )
        print('DIR_COUNT              : ' + columns[4])
        print('FILE_COUNT             : ' + columns[5])
        print('CONTENT_SIZE           : ' + convert_size(columns[6]))

    print_size('/projects/evaluate/*')
    print_size('/projects/evaluate/data/*')
    print_size('/projects/evaluate/data/dhr/*')

if __name__ == "__main__":
    main()
