# GCP-Genie — Research & Technical Overview

**Author:** Joshua T. Buxton  
**Topic:** GCP Subdomain Takeover via Dangling A Records

---

## Table of Contents

1. [What is a Subdomain?](#1-what-is-a-subdomain)
2. [What is DNS and how do A Records work?](#2-what-is-dns-and-how-do-a-records-work)
3. [What is a Subdomain Takeover?](#3-what-is-a-subdomain-takeover)
4. [The GCP-Specific Vector](#4-the-gcp-specific-vector)
5. [Why Dangling Records Happen](#5-why-dangling-records-happen)
6. [What an Attacker Can Do](#6-what-an-attacker-can-do)
7. [How GCP-Genie Works — Step by Step](#7-how-gcp-genie-works--step-by-step)
8. [The IP Reservation Technique](#8-the-ip-reservation-technique)
9. [Defensive Mitigations](#9-defensive-mitigations)
10. [Legal & Ethical Scope](#10-legal--ethical-scope)

---

## 1. What is a Subdomain?

A subdomain is a prefix attached to a main domain name. For example:

~~~
mail.google.com       ← "mail" is the subdomain
careers.megacorp.com  ← "careers" is the subdomain
api.example.com       ← "api" is the subdomain
~~~

Large organizations can have hundreds or thousands of subdomains, each pointing to a different server or service. Managing all of them consistently over time is difficult, and that difficulty is exactly what this tool exploits.

---

## 2. What is DNS and How Do A Records Work?

DNS (Domain Name System) is the internet's phone book. When you type `careers.megacorp.com` into a browser, your computer asks DNS: "What IP address does this hostname map to?" DNS returns a number like `192.168.0.1`, and your browser connects to that IP.

An **A record** is the specific DNS entry that maps a hostname to an IPv4 address:

~~~
careers.megacorp.com.   A   192.168.0.1
~~~

This record is stored in the organization's DNS configuration and tells the entire internet where to find that subdomain. Changing or removing A records requires access to the organization's DNS provider — it doesn't happen automatically when a server is shut down.

---

## 3. What is a Subdomain Takeover?

A subdomain takeover occurs when:

1. An organization's DNS still has an A record pointing to an IP address
2. That IP address no longer belongs to the organization
3. An attacker claims that IP address
4. The subdomain now resolves to the attacker's server

At that point, the attacker fully controls what content is served at `careers.megacorp.com` (or whichever subdomain was taken over) — even though they have no access to the organization's DNS or infrastructure.

From a visitor's perspective, the URL looks completely legitimate.

---

## 4. GCP A Record Vector

Google Cloud Platform (GCP) uses **ephemeral IP addresses** by default for virtual machines (VMs). When you create a VM in GCP, it gets assigned a public IP from Google's shared pool. When that VM is deleted, the IP is released back into the Ephemeral IP address pool, and can be reassigned to anyone else's new VM.

This creates a window of vulnerability:

~~~
Organization's VM (192.168.0.1) ──► VM deleted ──► IP returned to GCP Ephemeral IP pool
        │
        └── DNS A record for subdomain.company.com still points to 192.168.0.1
                                                        ▲
                                          Attacker creates a new VM
                                          and gets assigned 192.168.0.1
~~~

Because Google's reverse DNS (PTR records) for GCP IPs resolve to hostnames ending in `*.bc.googleusercontent.com`, it is possible to identify whether a given IP address is part of Google's infrastructure.

---

## 5. Why Dangling Records Happen

In practice, most IT teams are often separate. When an engineer decommissions a VM, they may:

- Delete the VM and forget to update DNS
- Assume someone else will clean up the DNS record
- Not have access to the DNS management console
- Follow a decommission checklist that doesn't include DNS cleanup

The DNS A record then becomes **dangling** — it still exists and still points to an IP, but no server at that IP is under the organization's control. This is an extremely common operational mistake at scale.

---

## 6. What an Attacker Can Do

Once a subdomain takeover is successful, the attacker controls a trusted subdomain of a real organization. This enables a range of attacks:

**Credential Harvesting**  
Serve a convincing login page at `signin.company.com`. Users see a legitimate-looking URL in their browser and enter their credentials.

**Cookie Theft**  
Web browsers scope cookies to domains. Depending on how the organization's cookies are configured, a takeover of `sub.company.com` could allow reading cookies set for `.company.com`, exposing authenticated sessions.

**Bypassing Content Security Policy (CSP)**  
Many organizations whitelist their own subdomains in their CSP headers. A taken-over subdomain is already on the whitelist, allowing an attacker to host malicious scripts that the target site will trust.

**Email Spoofing**  
If the subdomain is used in SPF or DMARC email records, control of it can be leveraged to send email that appears to come from the organization.

**Reputation Abuse**  
Host malware, phishing pages, NSFW content or illegal content under the organization's brand, damaging their reputation and potentially their search rankings.

---

## 7. How GCP-Genie Works — Step by Step

GCP-Genie automates the entire discovery and exploitation chain. Here is exactly what happens when the tool runs:

### Step 1 — Subdomain Enumeration (Subfinder)

~~~bash
subfinder -d megacorp.com | anew output/megacorp.com/megacorp.com.txt
~~~

Subfinder queries dozens of public data sources — certificate transparency logs, DNS datasets, search engine results, and more — to build a comprehensive list of all known subdomains for the target domain. The `anew` tool deduplicates results so only newly discovered subdomains are added on subsequent runs.

### Step 2 — HTTP Probing (HTTPX)

~~~bash
httpx -l megacorp.com.txt -probe -ip | grep "FAILED"
~~~

Each discovered subdomain is probed over HTTP and HTTPS. Subdomains where the probe **fails** — meaning no web server responds — are the interesting ones. A failed HTTP probe on a subdomain that still has a DNS A record suggests the server behind that IP is gone.

The `-ip` flag captures the IP address that DNS resolved the subdomain to, even though no HTTP response came back.

### Step 3 — Google Ownership Verification (nslookup)

~~~bash
nslookup <IP> | grep "googleusercontent"
~~~

For each IP address extracted from the failed probes, a reverse DNS lookup is performed. GCP IPs have PTR records that resolve to `*.bc.googleusercontent.com`. If an IP returns this pattern, it confirms the IP belongs to Google's infrastructure — making it a candidate for GCP-based takeover.

### Step 4 — Region Identification (GCP IP Ranges)

~~~
https://www.gstatic.com/ipranges/cloud.json
~~~

Google publicly publishes the full list of IP ranges used by GCP, including which region each range belongs to. GCP-Genie downloads this file and uses Python's `ipaddress` module to match each candidate IP against these CIDR ranges. This tells the tool exactly which GCP region the IP lives in without making any API calls.

This step is critical because GCP static IP addresses are **regional resources** — you can only reserve an IP in the same region where it lives.

### Step 5 — Direct IP Reservation (gcloud)

~~~bash
gcloud compute addresses create takeover-megacorp-com \
    --addresses=192.168.0.1 \
    --region=us-central1 \
    --project=my-gcp-project
~~~

This is the core of the exploit. GCP allows you to reserve a specific external IP address by value, as long as that IP is currently unallocated in the pool. If the organization's VM is gone and the IP is free, this command succeeds immediately — the IP is now yours.

If the command fails, the IP is still in use elsewhere and cannot be claimed.

### Step 6 — VM Creation

Once the IP is reserved, a VM is created in the correct zone with that IP assigned to it. At this point:

- The organization's DNS still says `subdomain.company.com → 192.168.0.1`
- `192.168.0.1` is now the IP of your VM
- Any visitor to `subdomain.company.com` lands on your server

---

## 8. The IP Reservation Technique

An earlier approach to this class of attack used a **lottery method**: spin up VMs in a loop and hope GCP randomly assigns the target IP from its pool. This is extremely inefficient — GCP's IP pools contain millions of addresses, and the chance of a random hit is negligible. It also creates and destroys VMs continuously, generating cost and API rate limit exposure.

GCP-Genie uses **direct reservation** instead. The `gcloud compute addresses create --addresses=<IP>` API call attempts to claim a specific IP by value. The result is binary and immediate:

| Result | Meaning |
|--------|---------|
| Success | IP was unallocated — you now own it |
| Failure | IP is currently in use — not available |

This collapses what could be an infinite loop into a single API call per candidate IP.

---

## 9. Defensive Mitigations

For organizations looking to defend against this class of attack:

**Audit DNS regularly**  
Periodically compare every A record in your DNS zones against your current inventory of active infrastructure. Any A record pointing to an IP you no longer own is a liability.

**Automate DNS cleanup**  
Integrate DNS record removal into your VM decommission process. Infrastructure-as-code tools (Terraform, Pulumi) can manage DNS records alongside compute resources so they are deleted together.

**Use static IP reservations proactively**  
In GCP, if a subdomain points to a specific IP, reserve that IP as a static address in your project. Reserved IPs cannot be claimed by others even if no VM is currently using them.

**Monitor certificate transparency logs**  
Services like `crt.sh` log every TLS certificate issued for your domain. Unexpected certificates for your subdomains can be an early indicator of a takeover.

**Set short TTLs on A records tied to ephemeral resources**  
A low TTL (e.g., 60 seconds) means that when DNS is cleaned up, the stale record stops resolving quickly across the internet.

---

## 10. Legal & Ethical Scope

GCP-Genie is a security research and bug bounty tool. Using it against a target requires explicit written authorization. Unauthorized use against systems you do not own or have permission to test is illegal in most jurisdictions under laws such as the Computer Fraud and Abuse Act (CFAA) in the United States and equivalent legislation internationally.

Responsible use cases include:

- Authorized penetration testing engagements
- Bug bounty programs that explicitly include subdomain takeover in scope
- Internal red team assessments of your own organization's infrastructure
- Security research in controlled lab environments

Any subdomain takeover vulnerability discovered should be reported to the affected organization through responsible disclosure before any public release of findings.
