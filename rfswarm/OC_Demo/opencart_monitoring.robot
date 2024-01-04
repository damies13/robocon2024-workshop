*** Settings ***

Library 				SSHLibrary
Suite Setup 		Open Connection And Log In	${HOST}	${USERNAME}	${PASSWORD}
Suite Teardown 	Close All Connections

Library					String
Library					Collections
Library					RequestsLibrary
Library					json

*** Variables ***
${HOST}                192.168.13.69
${USERNAME}            PTMon
${PASSWORD}            ptm0n

*** Test Cases ***
Monitor Opencart Server

	${epoch}=		Get Time	epoch
	${stats}=	Collect Stats
	Post AUT Stats		${HOST} 	Opencart Server 	${epoch}    ${stats}
	Sleep	4


*** Keywords ***

Open Connection And Log In
	[Arguments] 	${HOST}=${HOST} 	${USERNAME}=${USERNAME} 	${PASSWORD}=${PASSWORD}
	# keywords from SHH Library
	Open Connection     ${HOST}		width=160
	Login               ${USERNAME}        ${PASSWORD}


Collect Stats
	${lscpu}=	lscpu
	${vmstat}=	vmstat

	${stats}=	Create Dictionary
	FOR 	${k}	IN		@{lscpu.keys()}
		log 	${k}
		Set To Dictionary	${stats} 	lscpu: ${k}		${lscpu["${k}"]}
	END
	FOR 	${k}	IN		@{vmstat.keys()}
		log 	${k}
		log 	${vmstat["${k}"]}
		Set To Dictionary	${stats} 	vmstat: ${k}		${vmstat["${k}"]}
	END
	[Return]	${stats}



lscpu
	Write              lscpu
	${output}=         Read Until       $
	# @{lines}=	Split To Lines	${output}
	@{lines}=	Set Variable	${output.splitlines()}

	${dict}=	Create Dictionary
	FOR 	${line} 	IN		@{lines}
		IF  len("${line}") > 3
			${key}	${val}=		Set Variable	${line.split(":", 1)}
			IF  "${key}" == "Flags" 		BREAK
			Set To Dictionary	${dict} 	${key.strip()}		${val.strip()}
		END
	END

	[Return] 	${dict}



vmstat
	${output}=		Execute Command		vmstat -w 1 2
	@{lines} =	Split To Lines	${output}
	log 	${lines[-1]}
	${line}=		Set Variable	${lines[-1]}
	@{vals} =	Split String	${line}
	log 	${vals}

	${vmstat}=	Create Dictionary
	# Proc
	#
	# r: The number of runnable processes. These are processes that have been launched and are either running or are waiting for their next time-sliced burst of CPU cycles.
	# b: The number of processes in uninterruptible sleep. The process isn’t sleeping, it is performing a blocking system call, and it cannot be interrupted until it has completed its current action. Typically the process is a device driver waiting for some resource to come free. Any queued interrupts for that process are handled when the process resumes its usual activity.
	Set To Dictionary	${vmstat} 	Processes: Runnable 		${vals[0]}
	Set To Dictionary	${vmstat} 	Processes: Uninterruptible	${vals[1]}


	# Memory
	#
	# swpd: the amount of virtual memory used. In other words, how much memory has been swapped out.,
	# free: the amount of idle (currently unused) memory.
	# buff: the amount of memory used as buffers.
	# cache: the amount of memory used as cache.
	Set To Dictionary	${vmstat} 	Memory: Swap 	${vals[2]}
	Set To Dictionary	${vmstat} 	Memory: Free 	${vals[3]}
	Set To Dictionary	${vmstat} 	Memory: Buffers	${vals[4]}
	Set To Dictionary	${vmstat} 	Memory: Cache 	${vals[5]}


	# Swap
	#
	# si: Amount of virtual memory swapped in from swap space.
	# so: Amount of virtual memory swapped out to swap space.
	Set To Dictionary	${vmstat} 	Swap: Swapped In 	${vals[6]}
	Set To Dictionary	${vmstat} 	Swap: Swapped Out	${vals[7]}


	# IO
	#
	# bi: Blocks received from a block device. The number of data blocks used to swap virtual memory back into RAM.
	# bo: Blocks sent to a block device. The number of data blocks used to swap virtual memory out of RAM and into swap space.
	Set To Dictionary	${vmstat} 	IO: Blocks received	${vals[8]}
	Set To Dictionary	${vmstat} 	IO: Blocks sent 	${vals[9]}


	# System
	#
	# in: The number of interrupts per second, including the clock.
	# cs: The number of context switches per second. A context switch is when the kernel swaps from system mode processing into user mode processing.
	Set To Dictionary	${vmstat} 	System: Interrupts/s		${vals[10]}
	Set To Dictionary	${vmstat} 	System: Context Switches/s	${vals[11]}


	# CPU
	#
	# These values are all percentages of the total CPU time.
	#
	# us: Time spent running non-kernel code. That is, how much time is spent in user time processing and in nice time processing.
	# sy: Time spent running kernel code.
	# id: Time spent idle.
	# wa: Time spent waiting for input or output.
	# st: Time stolen from a virtual machine. This is the time a virtual machine has to wait for the hypervisor to finish servicing other virtual machines before it can come back and attend to this virtual machine.
	Set To Dictionary	${vmstat} 	CPU: User	${vals[12]}
	Set To Dictionary	${vmstat} 	CPU: System	${vals[13]}
	Set To Dictionary	${vmstat} 	CPU: Idle	${vals[14]}
	Set To Dictionary	${vmstat} 	CPU: Wait	${vals[15]}
	Set To Dictionary	${vmstat} 	CPU: Stolen	${vals[16]}


	#
	[Return] 	${vmstat}




Post AUT Stats
	[Documentation]		SSH: Post AUT Stats
	[Arguments]		${AUT}	${AUTType}	${AUTTime}    ${Stats}

	# keyword from Requests Library, reuse the session rather than creating a new one if possible
	${exists}= 	Session Exists	rfs
	# Run Keyword Unless 	${exists} 	Create Session	rfs 	${RFS_SWARMMANAGER}
	IF  not(${exists})
		Create Session	rfs 	${RFS_SWARMMANAGER}
	END

	${data}=	Create Dictionary
	Set To Dictionary	${data} 	AgentName				${RFS_AGENTNAME}
	Set To Dictionary	${data} 	PrimaryMetric		${AUT}
	Set To Dictionary	${data} 	MetricType			${AUTType}
	Set To Dictionary	${data} 	MetricTime			${AUTTime}
	Set To Dictionary	${data} 	SecondaryMetrics	${Stats}

	# keyword from json Library
	# ${string_json}= 	json.Dumps	${data}

	# keyword from Requests Library
	# ${resp}=	Post Request	rfs 	/Metric 	${string_json}
	${resp}=	POST On Session	rfs 	/Metric 	json=${data}
	Log	${resp}
	Log	${resp.content}
	Should Be Equal As Strings	${resp.status_code}	200
