using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using net.openstack.Core.Domain;
using net.openstack.Providers.Rackspace;

namespace $rootnamespace$.Samples.openstack.net
{
    public static class openstack
    {

        private static CloudIdentity cloudId;

        private static int networkCount;
        private static int flavorCount;
        private static int imageCount;
        private static int serverCount;
        private static List<string> regionList;

        public static void Authenticate(string username, string apikey)
        {
            cloudId = CreateIdentity(username, apikey);
            Console.WriteLine("Successfully retrieved Token for user: {0}", cloudId.Username);
            Console.WriteLine("Press <Enter> to continue...");
            Console.ReadLine();
        }

        public static void RunAll(string username, string apikey)
        {

            BuildListOfRegions(cloudId);


            // Let's create A LOT of containers
            CreateThousandsOfContainers(cloudId);


            // Let's get a list of my containers (limited to 10,000; use 'marker' to get more)
            ListContainers(cloudId);


            // Let's get a list of MY servers.
            ListMyServers(cloudId);


            // Let's get a list of images.
            ListImages(cloudId);


            // Let's get a list of flavors.
            ListFlavors(cloudId);


            // Let's get a list of networks.
            ListNetworks(cloudId);



            // Create a network.
            //CreateNetwork(cloudId);



            // Spin up two servers just to demonstrate more than one.
            // Note that this merely launches the create process on the server
            // side. You must wait until the servers are ready before using them.
            //SpinUpServerInNetwork(cloudId);
            //SpinUpAndWait(cloudId);

            // Let's create a 100 GB volume
            CreateVolume("An example of a volume","mynewvolume", cloudId);

        }

        public static void RunCreateContainer(string username, string apikey, string containerName = null)
        {
            if (PromptUser("Do you wish to create a Container?"))
            {
                Console.WriteLine("Enter the name of the Container you wish to create:");
                containerName = Console.ReadLine();
                CreateContainer(containerName, cloudId);
                MakeContainerCDN(containerName, cloudId);
            }
        }

        public static void RunUpload(string username, string apikey, string containerName = null, string filePath = null)
        {
            if (PromptUser("Do you wish to upload a file?"))
            {
                CloudIdentity cloudId = CreateIdentity(username, apikey);
                UploadFile(cloudId);
            }
        }

        public static void RunUploadFolder(string username, string apikey)
        {
            if (PromptUser("Do you wish to upload an entire folder?"))
            {
                Console.WriteLine("Container name: ");
                string containerName = Console.ReadLine();

                Console.WriteLine("Path to folder: ");
                string daPath = Console.ReadLine();
                string[] filePaths = Directory.GetFiles(daPath);
                CloudIdentity cloudId = CreateIdentity(username, apikey);
                foreach (string filename in filePaths)
                {
                    UploadFile(cloudId, filename, containerName, Path.GetFileName(filename));
                    
                }
            }
        }
        public static void RunDownload(string username, string apikey)
        {
            if (PromptUser("Do you wish to download a file?"))
            {
                CloudIdentity cloudId = CreateIdentity(username, apikey);
                DownloadFile(cloudId);
            }

        }

        public static void RunDelete(string username, string apikey)
        {
            if (PromptUser("Do you wish to delete an object from a container?"))
            {
                CloudIdentity cloudId = CreateIdentity(
                    username,
                    apikey);
                DeleteFileInCDN(cloudId);
                DeleteContainer(cloudId);
            }
        }


        public static void DeleteFileInCDN(CloudIdentity cloudId)
        {
            Console.WriteLine("Container Name: ");
            string containerName = Console.ReadLine();

            Console.WriteLine("Object Name: ");
            string objectName = Console.ReadLine();

            var cloudFilesProvider = new CloudFilesProvider(cloudId);
            cloudFilesProvider.DeleteObject(containerName, objectName);
        }

        public static void DeleteContainer(CloudIdentity cloudId)
        {
            if (PromptUser("Do you wish to delete the Container?"))
            {
                Console.WriteLine("Container Name: ");
                string containerName = Console.ReadLine();

                var cloudFilesProvider = new CloudFilesProvider(cloudId);
                cloudFilesProvider.DeleteContainer(containerName);
            }
        }

        public static void DownloadFile(CloudIdentity cloudId, string containerName = null)
        {

            var cloudFilesProvider = new CloudFilesProvider(cloudId);
            if (string.IsNullOrEmpty(containerName))
            {
                Console.WriteLine("Container name: ");
                containerName = Console.ReadLine();
            }
            
            Console.WriteLine("Object Name: ");
            string objectName = Console.ReadLine();

            Console.WriteLine("Output Path: ");
            string outputPath = Console.ReadLine();

            cloudFilesProvider.GetObjectSaveToFile(containerName, outputPath, objectName);
        }

        public static CloudIdentity CreateIdentity(string username, string apikey)
        {
            try
            {
                Console.Write("Creating Identity object...");
                CloudIdentity foo = new CloudIdentity()
                {
                    Username = username,
                    APIKey = apikey
                };
                CloudIdentityProvider bar = new CloudIdentityProvider();
                UserAccess ua = bar.Authenticate(foo);
                Console.Write("Done.\n");
                return foo;
            }
            catch (Exception ex)
            {
                throw;
            }
        }

        public static void ListImages(CloudIdentity cloudId)
        {
            try
            {
                if (PromptUser("Do you want to list the images?"))
                {
                    Console.WriteLine("Getting list of all images with details...");
                    CloudServersProvider csp = new CloudServersProvider(cloudId);

                    foreach (string region in regionList)
                    {
                        System.Collections.IEnumerable images = csp.ListImagesWithDetails(region: region, imageType: ImageType.Base);
                        ImagesToConsole(images);
                        images = csp.ListImagesWithDetails(region: region, imageType: ImageType.Snapshot);
                        ImagesToConsole(images);
                    }
                }
            }
            catch (Exception ex)
            {
                throw;
            }
        }

        private static void ImagesToConsole(System.Collections.IEnumerable images)
        {
            foreach (ServerImage image in images)
            {
                Console.WriteLine("Image[{0}] name: {1}", imageCount, image.Name);
                Console.WriteLine("Image[{0}] Id: {1}", imageCount, image.Id);
                Console.WriteLine("Image[{0}] Type: {1}", imageCount, image.GetType());
                ++imageCount;
            }
        }

        public static void ListMyServers(CloudIdentity cloudId)
        {
            try
            {
                if (PromptUser("Do you want a list of all your servers?"))
                {
                    Console.WriteLine("Getting list of your servers...");

                    CloudIdentityProvider cip = new CloudIdentityProvider();

                    // Get the list of servers for each Region
                    foreach (string rgn in regionList)
                    {
                        CloudServersProvider csp = new CloudServersProvider(cloudId);
                        System.Collections.IEnumerable servers = csp.ListServersWithDetails(region: rgn);
                        foreach (Server server in servers)
                        {
                            Console.WriteLine("Server[{0}] name: {1}, in Region {2}", serverCount, server.Name, rgn);
                            Console.WriteLine(server.AccessIPv4);
        
                            ++serverCount;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                throw;
            }
        }

        private static void BuildListOfRegions(CloudIdentity cloudId)
        {
            CloudIdentityProvider cip = new CloudIdentityProvider();
                        
            // The following two lines of code will get a list of endpoints, i.e. "Regions"
            UserAccess ua = cip.GetUserAccess(cloudId);
            ServiceCatalog[] sc = ua.ServiceCatalog;


            // Get the list of servers for each Region

            regionList = new List<string>();
            foreach (Endpoint ep in sc[0].Endpoints)
            {
                regionList.Add(ep.Region);
            }
        }

        public static void CreateThousandsOfContainers(CloudIdentity cloudId)
        {
            if (PromptUser("Do you wish to create 110 containers?"))
            {
                CloudFilesProvider cfp = new CloudFilesProvider(cloudId);
                string containerName = string.Empty;
                int x = 0;
                do
                {
                    containerName = string.Format("ZZZZ_{0}", x.ToString("D6"));
                    Console.WriteLine("Creating container {0}", containerName);
                    cfp.CreateContainer(containerName);
                    x++;
                } while (x < 110);

            }
        }


        public static void ListContainers(CloudIdentity cloudId)
        {
            if (PromptUser("Do you want a list of your containers?"))
            {
                CloudFilesProvider cfp = new CloudFilesProvider(cloudId);
                IEnumerable<Container> listOfContainers = cfp.ListContainers();
                foreach (Container ctnr in listOfContainers)
                {
                    Console.WriteLine("Container: {0}", ctnr.Name);
                }
            }
        }

        public static void ListFlavors(CloudIdentity cloudId)
        {
            try
            {
                if (PromptUser("Do you want to list all the flavors?"))
                {
                    Console.Write("Getting list of all flavors with details...");
                    CloudServersProvider csp = new CloudServersProvider(cloudId);
                    System.Collections.IEnumerable flavors = csp.ListFlavorsWithDetails();
                    Console.Write("Done.\n");
                    foreach (FlavorDetails flavor in flavors)
                    {
                        Console.WriteLine("Flavor[{0}] name: {1}", flavorCount, flavor.Name);
                        Console.WriteLine("Flavor[{0}] RAM: {1}MB", flavorCount, flavor.RAMInMB);
                        Console.WriteLine("Flavor[{0}] DISK: (1)GB", flavorCount, flavor.DiskSizeInGB);
                        Console.WriteLine("Flavor[{0}] ID: {1}", flavorCount, flavor.Id);
                        ++flavorCount;
                    }
                }
            }
            catch (Exception ex)
            {
                throw;
            }
        }

        public static void ListNetworks(CloudIdentity cloudId)
        {
            try
            {
                if (PromptUser("Do you want a list of networks?"))
                {
                    Console.WriteLine("Getting list of all networks...");
                    CloudNetworksProvider cnp = new CloudNetworksProvider(cloudId);
                    IEnumerable<CloudNetwork> networks = cnp.ListNetworks(identity: cloudId, region: "ORD");
                    Console.WriteLine("Done.\n");
                    foreach (CloudNetwork network in networks)
                    {
                        Console.WriteLine("Network[{0}] name: {1}", networkCount, network.Label);
                        Console.WriteLine("Network[{0}] Id: {1}", networkCount, network.Id);
                        ++networkCount;
                    }
                    networks = cnp.ListNetworks(identity: cloudId, region: "IAD");

                    foreach (CloudNetwork network in networks)
                    {
                        Console.WriteLine("Network[{0}] name: {1}", networkCount, network.Label);
                        Console.WriteLine("Network[{0}] Id: {1}", networkCount, network.Id);
                        ++networkCount;
                    }
                    switch (networkCount)
                    {
                        case 0:
                            Console.WriteLine("No networks found.");
                            break;
                        case 1:
                            Console.WriteLine("One network listed.");
                            break;
                        default:
                            Console.WriteLine("{0} networks listed.", networkCount);
                            break;
                    }
                }
            }
            catch (Exception ex)
            {
            }
        }

        public static void CreateNetwork(string networkname, CloudIdentity cloudId)
        {
            try
            {
                if (PromptUser("Do you wish to create a New Network?"))
                {
                    Console.WriteLine("Enter the name of the New Network: ");
                    networkname = Console.ReadLine();

                    Console.WriteLine("Enter CIDR, e.g. 10.1.0.0/24");
                    string cidr = "10.1.0.0/24";
                    cidr = Console.ReadLine();

                    Console.Write("Creating Network...");
                    CloudNetworksProvider cnp = new CloudNetworksProvider(cloudId);
                    CloudNetwork cn = cnp.CreateNetwork(cidr, networkname);
                    Console.Write("Done.\n");
                }
            }
            catch (Exception ex)
            {
                throw;
            }
        }

        public static void RemoveNetwork(string networkId, CloudIdentity cloudId)
        {
            try
            {
                // Create Provider
                Console.Write("Attempting to Remove Network {0}...", networkId);
                CloudNetworksProvider cnp = new CloudNetworksProvider(cloudId);
                cnp.DeleteNetwork(networkId);
                Console.Write("Done.\n");
            }
            catch (Exception ex)
            {
                Console.Write("Done.\n");
                //throw;
            }
        }

        public static void SpinUpServerInNetwork(string servername, string imageId, string flavorId, string region, string networkId, CloudIdentity cloudId)
        {
            try
            {
                // Create Provider
                Console.Write("Creating Server {0}...", servername);
                CloudServersProvider csp = new CloudServersProvider(cloudId);

                // Create and populate the list of networks to join
                List<string> networkList = new List<string>();
                networkList.Add(networkId);
                IEnumerable<string> networks = networkList;

                NewServer newServer = csp.CreateServer(servername, imageId, flavorId, region: region);

                Console.Write("Done.\n");
                Console.WriteLine("Administrator Password for new server {0} is {1}", servername, newServer.AdminPassword);
            }
            catch (Exception ex)
            {
                throw;
            }
        }

        public static void SpinUpAndWait(string servername, string imageId, string flavorId, string region, CloudIdentity cloudId)
        {
            try
            {
                // Create Provider
                Console.WriteLine("Creating Server {0}...", servername);
                CloudServersProvider csp = new CloudServersProvider(cloudId);

                // Spin up a new Server
                NewServer newServer = csp.CreateServer(servername, imageId, flavorId, region: region);
                newServer.WaitForActive(progressUpdatedCallback: WriteStatus);
                csp.SetServerMetadataItem(servername, "metakey", "metavalue", identity: cloudId);
                Console.Write("Done.\n");
                Console.WriteLine("Administrator Password for new server {0} is {1}", servername, newServer.AdminPassword);
            }
            catch (Exception ex)
            {
                throw;
            }
        }

        public static void CreateVolume(string volumeDescription, string volumeName, CloudIdentity cloudId)
        {
            try
            {
                CloudBlockStorageProvider cbsp = new CloudBlockStorageProvider(cloudId);
                var vol = cbsp.CreateVolume(100, volumeDescription, volumeName);
            }
            catch (Exception ex)
            {
                throw;
            }
        }

        public static void CreateContainer(string containername, CloudIdentity cloudId)
        {
            try
            {
                CloudFilesProvider cfp = new CloudFilesProvider(cloudId);
                if (!IsContainerExist(containername, cloudId)){
                    ObjectStore objstr = cfp.CreateContainer(containername);
                }
            }
            catch (Exception ex)
            {
            }
        }

        public static bool IsContainerExist(string containerName, CloudIdentity cloudId)
        {
            try
            {
                CloudFilesProvider cfp = new CloudFilesProvider(cloudId);
                Dictionary<string, string> cdnHeaders = cfp.GetContainerHeader(containerName);
                return true;
            }
            catch (Exception ex)
            {
                // Container does not exist
                return false;
            }
        }

        public static void MakeContainerCDN(string containername, CloudIdentity cloudId)
        {
            try
            {
                if (PromptUser("Do you wish to make the Container a CDN?"))
                {
                    CloudFilesProvider cfp = new CloudFilesProvider(cloudId);
                    cfp.EnableCDNOnContainer(containername, true);
                    ContainerCDN cntnr = cfp.GetContainerCDNHeader(container: containername, identity: cloudId);
                    Console.WriteLine("URL for HTTP: {0}", cntnr.CDNUri);
                    Console.WriteLine("URL for HTTPS: {0}", cntnr.CDNSslUri);
                    Console.WriteLine("URL for iOS streaming: {0}", cntnr.CDNIosUri);
                    Console.WriteLine("URL for streaming: {0}", cntnr.CDNStreamingUri);
                }
            }
            catch (Exception ex)
            {
                throw;
            }
        }

        public static void UploadFile(CloudIdentity cloudId,
                                        string filepath = null,
                                        string containerName = null,
                                        string objectName = null)
        {
            try
            {
                CloudFilesProvider cfp = new CloudFilesProvider(cloudId);
                if (string.IsNullOrEmpty(filepath))
                {
                    Console.WriteLine("Path to file to be uploaded: ");
                    filepath = Console.ReadLine();
                }
                if (string.IsNullOrEmpty(containerName))
                {
                    Console.WriteLine("Name of Container: ");
                    containerName = Console.ReadLine();
                }
                if (string.IsNullOrEmpty(objectName))
                {
                    Console.WriteLine("Name of Object: ");
                    objectName = Console.ReadLine();
                }
                Dictionary<string, string> meta = new Dictionary<string, string>();
                meta.Add("X-Delete-After", "1500");
                cfp.CreateObjectFromFile(
                container: containerName,
                filePath: filepath,
                objectName: objectName, headers: meta);
            }   
            catch (Exception ex)
            {
                throw;
            }
        }

        private static void WriteStatus(int pct)
        {
            Console.WriteLine("{0}%", pct);
        }

        private static bool PromptUser(string prompt)
        {
            ConsoleKeyInfo cki;
            Console.Write(prompt + " (Y/N): ");
            cki = Console.ReadKey();
            Console.WriteLine();
            if (cki.Key.ToString().ToUpper() == "Y")
            {
                return true;
            }
            else
            {
                return false;
            }
        }
    }
}
