using log4net;
using net.openstack.Core.Domain;
using net.openstack.Core.Providers;
using net.openstack.Providers.Rackspace;
using net.openstack.Providers.Rackspace.Objects;
using net.openstack.Providers.Rackspace.Objects.Dns;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace RackspaceDNSService
{
    public class RackspaceDNSService
    {
        private IIdentityProvider _IdentityProvider;
        private CloudIdentity _NewRackspaceCloudIdentity;
        private UserAccess _UserAccess;
        private ILog log;

        /// <summary>
        /// Initializes a new instance of the RackspaceDNSService class.
        /// </summary>
        /// <param name="log"></param>
        public RackspaceDNSService(ILog log)
        {
            this.log = log;
        }

        public void Authenticate(string username, string apiKey)
        {
            if (string.IsNullOrEmpty(username) || string.IsNullOrEmpty(apiKey))
                throw new Exception("Configuration error, username or apiKey empty");

            _IdentityProvider = new CloudIdentityProvider();
            _NewRackspaceCloudIdentity = new RackspaceCloudIdentity() { Username = username, APIKey = apiKey };
            _UserAccess = _IdentityProvider.Authenticate(_NewRackspaceCloudIdentity);
        }

        public DnsDomain GetDomain(string domainName)
        {
            var dnsProvider = new net.openstack.Providers.Rackspace.CloudDnsProvider(_NewRackspaceCloudIdentity, "UK", false, _IdentityProvider);
            var domains = dnsProvider.ListDomainsAsync(domainName, null, null, CancellationToken.None);

            var domain = domains.Result.Item1.FirstOrDefault();

            if (domain == null)
                throw new Exception("Domain not found");
            return domain;
        }

        public void UpdateIPAddressForARecord(string domainName, string hostName, string newIP)
        {
            var domain = GetDomain(domainName);
            
            var dnsProvider = new net.openstack.Providers.Rackspace.CloudDnsProvider(_NewRackspaceCloudIdentity, "UK", false, _IdentityProvider);

            var record = dnsProvider.ListRecordsAsync(domain.Id, DnsRecordType.A, hostName, null, null, null, CancellationToken.None).Result.Item1.FirstOrDefault();

            if (record == null)
                throw new Exception("Hostname not found");

            if (record.Data != newIP)
            {

                var configRecord = new List<DnsDomainRecordUpdateConfiguration>();
                configRecord.Add(new DnsDomainRecordUpdateConfiguration(record, hostName, newIP));

                var dnsJob = dnsProvider.UpdateRecordsAsync(domain.Id, configRecord, net.openstack.Core.AsyncCompletionOption.RequestCompleted, CancellationToken.None, null).Result;
                log.Info("DNS Updated to new IP: " + newIP);
            }
        }

    }
}
