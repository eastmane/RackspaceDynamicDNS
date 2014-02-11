using System;
using System.Collections.Generic;
using System.Linq;
using RackspaceDNSService;
using System.Text;
using System.Threading.Tasks;
using log4net;
using log4net.Config;

namespace DynamicDNSConsole
{
    class Program
    {
        private static readonly ILog log = LogManager.GetLogger(typeof(RackspaceDNSService.RackspaceDNSService));

        static void Main(string[] args)
        {
            BasicConfigurator.Configure();

            try
            {
                var rsSvc = new RackspaceDNSService.RackspaceDNSService(log);

                rsSvc.Authenticate("***REMOVED***", "***REMOVED***");

                rsSvc.UpdateIPAddressForARecord("dm13.co.uk", "***REMOVED***", Utilities.GetPublicIP());
            }
            catch (Exception ex)
            {
                log.Error(ex);
            }

            Console.ReadLine();
        }
    }
}
