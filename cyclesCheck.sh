#!/bin/bash

# 检查参数数量
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <log_file_1> <log_file_2>"
    exit 1
fi

# 设置原始日志文件路径
log1=$1
log2=$2

# 设置每个文件块的行数，此处为300万行
lines_per_file=3000000

# 检查文件大小
echo "Size of $log1:"
ls -lh $log1

echo "Size of $log2:"
ls -lh $log2

# 分割文件
split -l $lines_per_file $log1 ${log1}_part_
split -l $lines_per_file $log2 ${log2}_part_

# 生成包含分割文件列表的数组
files1=(${log1}_part_*)
files2=(${log2}_part_*)

# 循环处理每个文件块
for ((i = 0; i < ${#files1[@]}; i++)); do
    if [ -f "${files2[$i]}" ]; then
        echo "Processing ${files1[$i]} and ${files2[$i]}..."
        node compareLogs.js ${files1[$i]} ${files2[$i]}
        echo ""
    else
        echo "No matching file chunk for ${files1[$i]}"
    fi
done

# 删除所有分割的临时文件
echo "Deleting temporary files..."
rm ${log1}_part_*
rm ${log2}_part_*

echo "Temporary files deleted."
