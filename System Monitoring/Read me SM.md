# **System Monitoring (Script in Bash)**

First of all, I want to share my mindset before creating this project. I envisioned myself working in a professional SOC Analyst setting and focused on designing a tool that would give me quick, seamless access to essential system data. I aimed to gather the most useful and efficient tools for real-time monitoring into a single, unified script—making all this information as quick and easy to access as checking the time or the daily weather.

## **Introduction**

This script is designed to monitor the general state of a system by displaying, at regular intervals, key information such as CPU usage, RAM usage, disk occupancy, Internet connection status, and other important metrics. This type of script is useful for system administrators, developers, and users looking to get a quick overview of their machine’s performance.

### **But before diving into the details, let’s take a quick look at the differences between coding in Bash and Python:**

Bash is a scripting language integrated into the Unix/Linux system, designed to execute system commands. Unlike Python, which is object-oriented, Bash is mainly procedural and relies on system commands like `grep`, `awk`, `ps`, etc. Bash is highly effective for simple automation scripts, file management, and direct interaction with the operating system. However, it lacks advanced data structures and is less readable for long and complex scripts.

Python, on the other hand, is a general-purpose programming language that is more readable and comes with many standard libraries. It is often preferred for complex tasks, data analysis, or application development. Python is also cross-platform and offers more advanced data structures (like dictionaries and lists), as well as more readable syntax. However, it can be less efficient than Bash for simple system administration scripts.

With this understanding in mind, let’s explore the monitoring script in Bash. We’ll break down each section to explain the reasoning and logic behind each line.


---

## **The Banner and Colors: A Professional and Engaging Script**

When the script starts, the first thing displayed is a banner. This banner is not just aesthetic but functional, as it identifies the script and immediately informs the user of its purpose.
[![Capture-d-cran-2024-11-15-034542.png](https://i.postimg.cc/tJDnwx83/Capture-d-cran-2024-11-15-034542.png)](https://postimg.cc/ZvBqyCbn)
````bash
echo -e "${BLUE}       ____  ____  ______              _____ __________  ____  ______${NC}"
echo -e "${BLUE}      / __ \\/ __ \\/ ____/           / ___// ____/ __ \\/ __ \\/ ____/${NC}"
echo -e "${BLUE}     / / / / / / / /       ______     \\__ \\/ /   / / / / /_/ / __/   ${NC}"
echo -e "${BLUE}    / /_/ / /_/ / /___    /_____/  ___/ / /___/ /_/ / ____/ /___    ${NC}"
echo -e "${BLUE}   /_____\\/____/\\____/            /____/\\____/\\____/_/   /_____/   ${NC}"
echo -e "${BLUE}============================= By LehBiker ===========================${NC}"
`````

The choice of this banner is also based on a key principle: making the script recognizable. In environments where multiple scripts or tools are used simultaneously, the banner acts as a visual landmark. It helps distinguish this program from others while creating a sense of familiarity for returning users.

But this presentation does not stop there. The script uses a defined color code to enhance the readability of the information displayed. These colors are not randomly chosen—they serve specific purposes:
- **Green** indicates successful operations, positive indicators, or stable elements. For example, when a package is successfully installed or when the network connection is active.
- **Yellow** draws attention to important points or potential warnings. It is a color that invites caution without signaling a critical error.
- **Red** is reserved for serious issues or alerts requiring immediate action, such as a command failure or the unavailability of an essential resource.
- **Blue** is used for general information or introductory elements. It is a calming color, ideal for establishing context without distracting the user.
[![Capture-d-cran-2024-11-15-035217.png](https://i.postimg.cc/288Zv0B2/Capture-d-cran-2024-11-15-035217.png)](https://postimg.cc/nMgrfY2D)
Here’s how these colors are integrated into the script:

```bash
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
```

These colors are defined using ANSI codes. These codes are interpreted by most Linux terminals to stylize the text. For example, when a command executes successfully, the corresponding text can be displayed in **green** to indicate success, saving the user from having to look through logs or error details. The code \033[0;32m indicates that the following text will be green until reset with \033[0m (No Color).

These choices are not only functional; they also contribute to making the user interface more welcoming and user-friendly. In an often austere environment like the terminal, such details demonstrate attention to user comfort.

**Verifying and Installing Required Packages**

Since this script depends on several utilities (`curl`, `net-tools`, `ifstat`, and `util-linux`), it’s crucial to ensure they are all installed. For this, we created an `install_if_missing` function that checks for each package using `dpkg -s`. If a package is missing, it is installed via `sudo apt-get install -y`. This approach ensures that the script can run without errors, even if some tools are initially missing.

Why use `dpkg -s`? This command is quick and silent, allowing you to check for a package’s presence without forcing an installation. The `&> /dev/null` redirects the output to "nowhere," so no unnecessary messages are shown to the user.

```bash
# Function to check and install required packages if missing
function install_if_missing {
    local package=$1
    if ! dpkg -s "$package" &> /dev/null; then
        echo -e "${YELLOW}Installing $package...${NC}"
        sudo apt-get install -y "$package" &> /dev/null
        echo -e "${GREEN}$package installed successfully.${NC}"
    else
        echo -e "${BLUE}$package is already installed.${NC}"
    fi
}

# Check and install necessary packages
REQUIRED_PACKAGES=("curl" "net-tools" "ifstat" "util-linux")
for package in "${REQUIRED_PACKAGES[@]}"; do
    install_if_missing "$package"
done
```

---


## **System Metrics Collection: Real-Time RAM and CPU Monitoring**

### **Monitoring RAM: A Key Indicator of System Health**

Random Access Memory (RAM) is a fundamental resource for any computer system. It largely determines the system's ability to run multiple processes simultaneously. Overloading RAM can cause slowdowns or crashes as the system is forced to move data to the disk, a much slower process.
[![Capture-d-cran-2024-11-15-035542.png](https://i.postimg.cc/HnWVwLjV/Capture-d-cran-2024-11-15-035542.png)](https://postimg.cc/jw9xKtHb)
In this script, the following command is used to monitor RAM:

```bash
RAM_USAGE=$(free | grep Mem | awk '{printf "%.2f", $3/$2 * 100}')
echo -e "${GREEN}Utilization of RAM:${NC}"
progress_bar ${RAM_USAGE%.*}
echo ""
```

The free command is a native Linux tool that provides detailed statistics on memory usage. Here’s how this command is broken down:
1. free generates a table showing total, used, free, and available memory.
2. grep Mem filters only the relevant line containing information about physical memory.
3. awk extracts the necessary columns (used and total memory) and calculates the percentage of memory used by dividing the consumed memory by the total memory. The result is formatted to two decimal places for greater precision.

This metric is then displayed to the user, but not in raw form. To make this data more understandable, it is visualized with a progress bar:

```bash
echo -e "${GREEN}Utilization of RAM:${NC}"
progress_bar ${RAM_USAGE%.*}
echo ""
```

The progress_bar function, detailed later, transforms this percentage into a segmented bar, where each block represents 10% of the RAM used. This visualization is essential because it allows the user to grasp the information at a glance without needing to interpret a numerical percentage.

---

### **CPU Load: The System’s Power in a Snapshot**

The CPU, or central processing unit, is the brain of any computer system. Prolonged CPU overload can slow down all operations, from running applications to handling basic system tasks. Monitoring the CPU is therefore crucial for diagnosing performance issues and understanding which processes consume the most resources.

Here’s how the script retrieves CPU load:

```bash
CPU_LOAD=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
CPU_LOAD=${CPU_LOAD%.*}
```

This command uses top, a powerful tool for monitoring processes and system resources. The command is executed in batch mode (-bn1), allowing it to capture data without interactive interface interference. The line containing Cpu(s) is then extracted with grep, and awk calculates the percentage of CPU used by subtracting the idle percentage **(%idle) from 100**.

As with RAM, this information is displayed with a progress bar:

```bash
echo -e "${YELLOW}CPU Load: ${CPU_LOAD}%${NC}"
progress_bar $CPU_LOAD
echo ""
```

Visualizing CPU load in this way is particularly useful in a SOC environment. It allows immediate identification of whether the CPU is under pressure without needing to interpret complex numerical values. For example, a bar filled to 80% or more might indicate that one or more processes are consuming a disproportionate amount of resources.

---



## **System Uptime and Disk Space Monitoring**
[![Capture-d-cran-2024-11-15-141159.png](https://i.postimg.cc/0Ngjtnbg/Capture-d-cran-2024-11-15-141159.png)](https://postimg.cc/qNLpq8sQ)
### **System Uptime: Measuring Continuity**

System uptime is a fundamental metric for evaluating stability. A server that frequently reboots may indicate configuration issues, hardware failures, or even intentional attacks. In this script, the uptime is retrieved with the following command:

```bash
echo -e "${GREEN}Uptime: $(uptime -p)${NC}"
```

The ** uptime -p ** command produces a clear, human-readable output, such as "up 2 days, 4 hours." This information allows a SOC Analyst to quickly confirm whether the system is operating continuously or if suspicious interruptions need to be investigated.

---

### **Disk Space: Preventing Interruptions from Storage Overload**

Insufficient disk space can have disastrous consequences on a system. Logs cannot be saved, databases stop functioning, and even critical system processes may be affected. To prevent this, the script analyzes each partition and displays its usage rate:

```bash
echo -e "${BLUE}Disk Space:${NC}"
df -h --output=source,pcent,used,size | grep '^/dev/' | while read -r source pcent used size; do
    echo -e "${BLUE}${source}:${NC} ${pcent} (${used} used out of ${size})"
    disk_usage=${pcent%\%}
    progress_bar "$disk_usage"
    echo ""
done
```

Here’s how this works:
1. **df -h**: Generates a report on disk usage, formatted for readability.
2. **--output=source,pcent,used,size**: Filters columns to display only essential information: partition (source), percentage used (pcent), space used (used), and total size (size).
3. **grep '^/dev/'**: Limits results to locally mounted partitions.
4. **progress_bar**: Provides a visual representation of disk usage, where a nearly full bar signals a critical partition (close to 100% usage).

This section helps SOC Analysts anticipate storage issues, which is crucial to ensure the continuous availability of services.

---

## **Network Analysis: Bandwidth, IP, and DNS**

### **Network Speed: A Quick Evaluation of Connectivity**

In cybersecurity environments, monitoring bandwidth is essential for detecting network anomalies. Unusually high or low bandwidth could signal an attack, unauthorized downloads, or a service outage.

```bash
echo -e "${GREEN}===== CONNECTION SPEED =====${NC}"
ifstat -t 1 1 | tail -n 1 | awk '{print "Download: " $1 " KB/s | Upload: " $2 " KB/s"}'
```

The `ifstat`  command monitors bandwidth in real time. In batch mode, it records download and upload rates expressed in kilobytes per second. This information is useful for identifying suspicious network activity or verifying whether the system is using bandwidth optimally.

---

### **IP Addresses and DNS Servers**

A thorough analysis of listening IP addresses and configured DNS servers is also essential. These data points help verify whether the system is communicating with the correct servers or if unexpected or malicious connections are open.

```bash
echo -e "${YELLOW}===== IP ADDRESSES AND DNS =====${NC}"
echo -e "${BLUE}Listening Public and Private IP Addresses:${NC}"
sudo netstat -tuln | awk '{print $4}' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]+' | sort | uniq

echo -e "${GREEN}Configured DNS:${NC}"
grep 'nameserver' /etc/resolv.conf | awk '{print $2}'
```

1. **`netstat -tuln`**  : Lists active network connections and listening ports.
2. **`grep`** : Filters IPv4 addresses, eliminating irrelevant lines.
3. **`sort | uniq`**: Sorts results and removes duplicates, keeping only unique addresses.
4. **`grep 'nameserver'`**: Extracts configured DNS servers from the /etc/resolv.conf file.

These details help diagnose connectivity issues, such as misconfigured DNS or unexpected listening ports.

---

## **Security: Protecting the System and Detecting Threats**

### Downloads History
[![Capture-d-cran-2024-11-14-22330922.png](https://i.postimg.cc/BZr4x6yb/Capture-d-cran-2024-11-14-22330922.png)](https://postimg.cc/xq3wQ09V)
This script aims to provide a quick and structured overview of the latest software installations performed on the system, as well as the most recently downloaded files. It is primarily intended for system administrators or technical users who want to save time when reviewing recent activities.

```bash
Copier le code
echo -e "${YELLOW}===== INSTALLATION HISTORY =====${NC}"
    tail -n 10 /var/log/dpkg.log 2>/dev/null || echo "Log not found"
    find ~/Downloads -type f -printf '%TY-%Tm-%Td %TH:%TM %p\n' | sort -r | head -n 10
```
Subsequently, we had to add this line of script to achieve the following:

```bash
find ~/Downloads -type f -printf '%TY-%Tm-%Td %TH:%TM %p\n' | sort -r | head -n 10
This command lists the 10 most recently downloaded files in the ~/Downloads folder.
```
*`find ~/Downloads`*: Searches in the user's Downloads directory.
*`-type f`*: Limits the search to files only (excludes directories).
*`-printf '%TY-%Tm-%Td %TH:%TM %p\n'`*:
Provides a custom display format for each file found:
*`%TY-%Tm-%Td`*: Outputs the date of the last modification in the YYYY-MM-DD format.
*`%TH:%TM`*: Outputs the time of the last modification in the HH:MM format.
*`%p`*: Displays the full file path.
*`| sort -r`*: Sorts the results by modification date in descending order (most recent files appear first).
*`| head -n 10`*: Extracts and displays only the first 10 entries from the sorted list.
This addition allows for quick identification of the most recently modified or downloaded files, making it especially useful for tracking user activity or retrieving recent downloads efficiently.

---
### **Failed Login Attempts: Monitoring Brute Force Attacks**

Brute force attacks are a common method for compromising systems. They involve trying multiple passwords until the correct one is found. The script analyzes system logs to detect these attempts and alert the user:

```bash
failed_attempts=$(grep "Failed password" /var/log/auth.log | tail -n 10)
if [ -z "$failed_attempts" ]; then
    echo -e "${GREEN}No failed login attempts${NC}"
else
    echo "$failed_attempts"
fi
```

By retrieving the last 10 failed login attempts, the script enables real-time detection of anomalies. A series of close-proximity failures might indicate unauthorized access attempts requiring immediate action.

---

### **Critical Services Status: SSH and Firewall**

To further enhance security, the script checks the status of two critical services:** SSH **and the ** UFW** firewall.

```bash
echo -e "${BLUE}Critical Services Status:${NC}"
echo -e "SSH: $(systemctl is-active ssh)"
echo -e "Firewall (UFW): $(systemctl is-active ufw)"
```

These commands use systemctl to verify whether the services are active or inactive. Here’s why these checks are important:
- `SSH`: This service enables remote access to the system. If it is inactive when it should be active, this may indicate a configuration issue. Conversely, if SSH is active but not needed, it could increase the attack surface.
- `Firewall (UFW)`: The firewall is a first line of defense against external attacks. If the service is inactive, the system becomes exposed to potential threats.

This information provides an instant overview of the system’s security posture, allowing the SOC Analyst to take corrective measures if necessary.

---

## **In-Depth Process Analysis**

### **Processes Using the CPU: Identifying Bottlenecks**

The CPU (Central Processing Unit) is the core of any computer system, responsible for executing instructions and coordinating the operations of all other hardware components. When one or more processes consume an excessive share of the CPU, it can lead to overall system slowdowns or even critical failures. High CPU usage might be caused by poorly optimized software, infinite loops in code, or, more worryingly, malicious activities such as unauthorized cryptocurrency mining.

To address this, the script includes a section to identify and analyze the most CPU-intensive processes in real time:

```bash
ps aux --sort=-%cpu | awk 'NR>1 {print $1, $2, $3, $11}' | head -n 10 | while read user pid cpu cmd; do
    printf "%-15s %-10s %-10s " "$user" "$pid" "$cmd"
    progress_bar "${cpu%.*}"
    echo ""
done
```

This code works as follows:
1. **`ps aux`**: Lists all active processes with detailed information, including the user running the process, the process ID (PID), the percentage of CPU it is consuming, and the associated command.
2. **`--sort=-%cpu`**: Sorts the processes in descending order by CPU usage so that the most resource-intensive ones appear at the top.
3. **`awk`**: Extracts specific columns for display: user, PID, CPU usage, and the command name.
4. **`head -n 10`**: Limits the output to the top 10 most CPU-intensive processes, ensuring clarity and focus.
5. **`progress_bar`**: Visualizes the CPU usage of each process as a percentage using a progress bar for intuitive understanding.

The progress bar is particularly useful for providing immediate insights into the impact of each process. A process showing 90% CPU usage, for example, is a clear signal of a potential issue, especially if it is not a critical system process.

**Why is this critical for SOC analysts?**
High CPU usage is often an early indicator of a problem. Some scenarios where this analysis proves invaluable include:
- **Application Errors**: Applications stuck in infinite loops or overusing resources can monopolize the CPU, affecting overall system performance.
- **Malware Detection**: Certain types of malware, such as cryptominers or DDoS agents, often exhibit high CPU consumption. Identifying these processes quickly allows analysts to take immediate action.
- **Capacity Planning**: By monitoring which processes consistently consume the most resources, SOC teams can plan hardware upgrades or optimize resource allocation.

---

### **Processes Using Memory: Monitoring RAM Bottlenecks**

Random Access Memory (RAM) is a finite but critical resource in any system. While the CPU handles processing tasks, RAM acts as a high-speed storage medium, ensuring smooth execution of processes. Excessive memory usage by a single process can lead to slower performance or even crashes, as the system resorts to using the much slower swap space on disk.

The script helps monitor memory usage and pinpoint the most RAM-intensive processes using the following code:

```bash
ps aux --sort=-%mem | awk 'NR>1 {print $1, $2, $4, $11}' | head -n 10 | while read user pid mem cmd; do
    printf "%-15s %-10s %-10s " "$user" "$pid" "$cmd"
    progress_bar "${mem%.*}"
    echo ""
done
```
[![Capture-d-cran-2024-11-15-142211.png](https://i.postimg.cc/NF4Yx8Zc/Capture-d-cran-2024-11-15-142211.png)](https://postimg.cc/rRKvV48n)
Here’s a detailed breakdown of its functionality:
1. **`ps aux`**: Retrieves all active processes, including details about memory usage.
2. **`--sort=-%mem`**: Sorts the processes by percentage of memory consumption in descending order.
3. **`awk`**: Filters the relevant columns: user, PID, memory usage, and command.
4. **`head -n 10`**: Restricts the output to the top 10 memory-consuming processes, keeping the analysis concise and actionable.
5. **`progress_bar`**: Converts the memory usage percentage into a graphical bar for easier interpretation.

The visualization makes it clear at a glance if a process is consuming an alarming amount of memory, helping to quickly identify potential issues.

**Why is this important for SOC analysts?**
Monitoring memory usage is crucial not only for performance but also for detecting anomalies:
- **Memory Leaks**: Poorly coded applications can have memory leaks, gradually consuming more and more RAM until the system crashes. These processes often show consistently increasing memory usage.
- **Malware Activity**: Some malicious software loads significant data into memory to perform its tasks, such as spying or data exfiltration.
- **Performance Optimization**: By identifying processes consuming excessive RAM, SOC analysts can optimize workloads or even reassign processes to less critical systems.

---

### **A Final Note on Resource Monitoring**

The combination of CPU and memory monitoring provides SOC teams with a comprehensive view of system resource utilization. By analyzing this data, analysts can:
- Quickly diagnose performance issues and take corrective actions.
- Spot anomalies that may indicate malicious activities.
- Optimize system efficiency, ensuring critical applications have the resources they need.

These sections of the script are not just diagnostic tools; they serve as an early warning system, giving SOC analysts the ability to act before minor issues escalate into major incidents.

---

### Here’s the end of this brief presentation! If you’ve made it this far, I’m sure you’ll have the best monitoring system in your entire circle!
### I hope you enjoyed the documentation and that it will be useful to you. Feel free to share it customize it according to your needs.
# See you soon for another ride!
