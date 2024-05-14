const fs = require('fs');
const readline = require('readline');

function getTimestamp() {
  const date = new Date();

  const formatter = new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
    timeZone: 'Asia/Shanghai'
  });

  let formattedDate = formatter.format(date);
  formattedDate = formattedDate.replace(/(\d{2})\/(\d{2})\/(\d{4}), (\d{2}):(\d{2}):(\d{2})/, `$3-$1-$2 $4:$5:$6`);

  const milliseconds = String(date.getMilliseconds()).padStart(3, '0');
  return `${formattedDate}.${milliseconds}`;
}

async function compareLogs(file1, file2) {
  console.log(`${getTimestamp()} Comparing files: ${file1} vs ${file2}`); // 添加此行来打印正在比较的文件名

  const stream1 = fs.createReadStream(file1);
  const stream2 = fs.createReadStream(file2);

  const rl1 = readline.createInterface({
    input: stream1,
    crlfDelay: Infinity
  });

  const rl2 = readline.createInterface({
    input: stream2,
    crlfDelay: Infinity
  });

  const regex = /\[block_verifier\] block number: (\d+), hash: Byte32\(.*?\), size:.*?, cycles: (\d+)\/\d+/;

  let line1 = rl1[Symbol.asyncIterator]();
  let line2 = rl2[Symbol.asyncIterator]();

  let lineCount = 1;
  let allMatch = true;

  while (true) {
    const result1 = await line1.next();
    const result2 = await line2.next();

    // Check if either file is done
    if (result1.done || result2.done) {
      if (!result1.done || !result2.done) {
        console.log("Error: Files have different number of lines.");
        allMatch = false;
      }
      break;
    }

    const match1 = result1.value.match(regex);
    const match2 = result2.value.match(regex);

    if (!match1 || !match2) {
      console.log(`No matching data found on line ${lineCount}`);
      allMatch = false;
      lineCount++;
      continue;
    }

    if (match1[1] !== match2[1]) {
      console.log(`Block number mismatch at line ${lineCount}: ${file1} has block number ${match1[1]}, ${file2} has block number ${match2[1]}`);
      allMatch = false;
      break;
    }

    if (match1[2] !== match2[2]) {
      console.log(`${getTimestamp()} Mismatch found in block number: ${match1[1]} at line ${lineCount} | ${file1} cycles: ${match1[2]} | ${file2} cycles: ${match2[2]}`);
      allMatch = false;
    }

    lineCount++;
  }

  rl1.close();
  rl2.close();

  if (allMatch) {
    console.log(`${getTimestamp()} All cycles match`);
  }
}

const file1 = process.argv[2];
const file2 = process.argv[3];

if (!file1 || !file2) {
  console.log("Please provide two log file paths.");
} else {
  compareLogs(file1, file2);
}
