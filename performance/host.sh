#!/bin/bash -x

do_taskset_p ()
{
	MASK="$1"; shift
	for i in "$@"; do
		taskset -p $MASK $i
	done
}

for i in $(grep eth0 /proc/interrupts | cut -f 1 -d :); do
	echo 4 > /proc/irq/$i/smp_affinity_list
done

if ! ip link sh | grep tap0: > /dev/null; then
	# User Networking
	do_taskset_p 1 $(pidof netserver)
	exit
fi

if ! ip link sh br0 > /dev/null; then
	ip addr add 10.0.99.2/24 dev tap0
	ip link set mtu 9000 dev tap0
	ip link set up dev tap0
fi

VHOST_PIDS="$(pidof vhost-$(pidof qemu-system-x86_64))"
if [ -n "$VHOST_PIDS" ]; then
	# vhost-net
	do_taskset_p 10 $(pidof vhost-$(pidof qemu-system-x86_64))
	do_taskset_p 1 $(pidof netserver)
else
	# virtio or emulated
	do_taskset_p 11 $(pidof netserver)
fi
