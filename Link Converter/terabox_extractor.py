"""
TeraBox Link Extractor Module
Converts TeraBox share links to direct streaming URLs using ndus cookie authentication
"""

import requests
import json
import re
from urllib.parse import urlparse, parse_qs, unquote


class TeraBoxExtractor:
    def __init__(self, ndus_cookie):
        """
        Initialize the extractor with ndus cookie for authentication
        
        Args:
            ndus_cookie (str): The ndus cookie value from TeraBox session
        """
        self.ndus_cookie = ndus_cookie
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'application/json, text/plain, */*',
            'Accept-Language': 'en-US,en;q=0.9',
            'Referer': 'https://www.terabox.com/',
            'Origin': 'https://www.terabox.com',
        })
        if self.ndus_cookie:
            # Set cookie for all possible domains
            for domain in ['.terabox.com', '.teraboxshare.com', '.1024tera.com']:
                self.session.cookies.set('ndus', self.ndus_cookie, domain=domain)
                self.session.cookies.set('browserid', self.ndus_cookie[:32], domain=domain)
    
    def extract_surl(self, share_link):
        """
        Extract surl from TeraBox share link
        
        Args:
            share_link (str): TeraBox share link
            
        Returns:
            str: Extracted surl or None
        """
        try:
            # Normalize the URL - handle teraboxshare.com, 1024tera.com, etc.
            share_link = share_link.replace('teraboxshare.com', 'terabox.com')
            share_link = share_link.replace('1024tera.com', 'terabox.com')
            
            # Match patterns like /s/1abc or /wap/share/file?surl=abc
            match = re.search(r'/s/([a-zA-Z0-9_-]+)', share_link)
            if match:
                return match.group(1)
            
            # Try parsing as URL parameter
            parsed = urlparse(share_link)
            params = parse_qs(parsed.query)
            if 'surl' in params:
                return params['surl'][0]
            
            return None
        except Exception as e:
            print(f"Error extracting surl: {e}")
            return None
    
    def get_file_info(self, surl):
        """
        Get file information from TeraBox API
        
        Args:
            surl (str): Short URL identifier
            
        Returns:
            dict: File information or None if failed
        """
        try:
            # Get jsToken and cookies from share page first
            js_token = self._get_js_token(surl)
            
            # Try the main API endpoint
            api_url = "https://www.terabox.com/share/list"
            
            # Try with different parameter combinations
            param_sets = [
                {
                    'shorturl': surl,
                    'root': '1',
                    'web': '1',
                    'channel': 'dubox',
                    'app_id': '250528',
                    'jsToken': js_token,
                    'dp-logid': '',
                },
                {
                    'app_id': '250528',
                    'web': '1',
                    'channel': 'dubox',
                    'clienttype': '0',
                    'showempty': '0',
                    'num': '20',
                    'page': '1',
                    'dir': '/',
                    'shorturl': surl,
                    'root': '1'
                }
            ]
            
            for i, params in enumerate(param_sets):
                print(f"[DEBUG] Trying parameter set {i+1}")
                print(f"[DEBUG] Requesting API with surl: {surl}")
                print(f"[DEBUG] jsToken: {js_token}")
                
                response = self.session.get(api_url, params=params, timeout=15)
                
                print(f"[DEBUG] Response status: {response.status_code}")
                
                if response.status_code == 200:
                    try:
                        data = response.json()
                        errno = data.get('errno')
                        print(f"[DEBUG] API Response: errno={errno}, errmsg={data.get('errmsg', 'None')}")
                        
                        if errno == 0:
                            file_list = data.get('list', [])
                            if file_list:
                                print(f"[DEBUG] Found {len(file_list)} file(s)")
                                return file_list[0]  # Return first file
                            else:
                                print("[DEBUG] No files in response")
                        elif errno == -1:
                            print("[DEBUG] Error -1: Cookie invalid or expired")
                        elif errno == 140:
                            print("[DEBUG] Error 140: Authentication failed - trying next method")
                            continue
                        else:
                            error_msg = data.get('errmsg', 'Unknown error')
                            print(f"[DEBUG] API Error {errno}: {error_msg}")
                    except json.JSONDecodeError as e:
                        print(f"[DEBUG] Failed to parse JSON response: {e}")
                        print(f"[DEBUG] Response text: {response.text[:200]}")
                else:
                    print(f"[DEBUG] HTTP Error: {response.status_code}")
                    print(f"[DEBUG] Response: {response.text[:200]}")
            
            return None
        except Exception as e:
            print(f"[DEBUG] Exception in get_file_info: {e}")
            import traceback
            traceback.print_exc()
            
            return None
        except Exception as e:
            print(f"Error getting file info: {e}")
            return None
    
    def _get_js_token(self, surl):
        """
        Get jsToken by visiting the share page
        
        Args:
            surl (str): Short URL identifier
            
        Returns:
            str: jsToken or empty string
        """
        try:
            share_url = f"https://www.terabox.com/s/{surl}"
            print(f"[DEBUG] Fetching jsToken from: {share_url}")
            
            response = self.session.get(share_url, timeout=15)
            print(f"[DEBUG] Share page status: {response.status_code}")
            
            # Try multiple patterns to find jsToken
            patterns = [
                r'jsToken.*?:.*?"([a-zA-Z0-9]+)"',
                r'"jsToken"\s*:\s*"([a-zA-Z0-9]+)"',
                r'jsToken\s*=\s*"([a-zA-Z0-9]+)"',
                r'window\.jsToken\s*=\s*"([a-zA-Z0-9]+)"'
            ]
            
            for pattern in patterns:
                match = re.search(pattern, response.text)
                if match:
                    token = match.group(1)
                    print(f"[DEBUG] jsToken found: {token}")
                    return token
            
            # Try to extract from JSON data
            json_match = re.search(r'locals\.mset\((.*?)\);', response.text, re.DOTALL)
            if json_match:
                try:
                    json_str = json_match.group(1)
                    # Clean up JavaScript to make it valid JSON
                    json_str = re.sub(r'(\w+):', r'"\1":', json_str)
                    data = json.loads(json_str)
                    if 'jsToken' in data:
                        token = data['jsToken']
                        print(f"[DEBUG] jsToken found in JSON: {token}")
                        return token
                except:
                    pass
            
            print("[DEBUG] jsToken not found in page, generating fallback")
            # Generate a simple token as fallback
            import hashlib
            import time
            fallback = hashlib.md5(f"{surl}{time.time()}".encode()).hexdigest()[:16]
            print(f"[DEBUG] Using fallback token: {fallback}")
            return fallback
            
        except Exception as e:
            print(f"[DEBUG] Error getting jsToken: {e}")
            return ""
    
    def get_direct_link(self, share_link):
        """
        Convert TeraBox share link to direct streaming URL
        
        Args:
            share_link (str): TeraBox share link
            
        Returns:
            tuple: (direct_url, filename, error_message)
        """
        try:
            # Validate cookie
            if not self.ndus_cookie:
                return None, None, "ndus cookie is required"
            
            # Extract surl from share link
            surl = self.extract_surl(share_link)
            if not surl:
                return None, None, "Invalid TeraBox link format"
            
            # First try: API method
            print("[DEBUG] Trying API method...")
            file_info = self.get_file_info(surl)
            if file_info:
                # Extract direct download link
                dlink = file_info.get('dlink')
                filename = file_info.get('server_filename', 'video')
                
                if dlink:
                    # Get actual streaming URL (may redirect)
                    try:
                        response = self.session.head(dlink, allow_redirects=True, timeout=10)
                        direct_url = response.url
                        return direct_url, filename, None
                    except:
                        return dlink, filename, None
            
            # Second try: Extract from share page HTML
            print("[DEBUG] API failed, trying HTML extraction method...")
            return self._extract_from_html(surl)
            
        except Exception as e:
            return None, None, f"Exception: {str(e)}"
    
    def _extract_from_html(self, surl):
        """
        Extract direct link from share page HTML
        
        Args:
            surl (str): Short URL identifier
            
        Returns:
            tuple: (direct_url, filename, error_message)
        """
        try:
            share_url = f"https://www.terabox.com/s/{surl}"
            print(f"[DEBUG] Extracting from HTML: {share_url}")
            
            response = self.session.get(share_url, timeout=15)
            
            if response.status_code != 200:
                return None, None, f"Failed to load share page (status {response.status_code})"
            
            html = response.text
            
            # Try to find file information in JavaScript variables
            patterns = [
                r'window\.jsData\s*=\s*({.*?});',
                r'locals\.mset\(({.*?})\);',
                r'yunData\.setData\(({.*?})\);'
            ]
            
            for pattern in patterns:
                match = re.search(pattern, html, re.DOTALL)
                if match:
                    try:
                        json_str = match.group(1)
                        # Try to parse as JSON
                        data = json.loads(json_str)
                        
                        # Look for file list
                        file_list = None
                        if 'file_list' in data:
                            file_list = data['file_list']
                        elif 'list' in data:
                            file_list = data['list']
                        
                        if file_list and len(file_list) > 0:
                            file_info = file_list[0]
                            dlink = file_info.get('dlink')
                            filename = file_info.get('server_filename', 'video')
                            
                            if dlink:
                                print(f"[DEBUG] Found link in HTML: {filename}")
                                return dlink, filename, None
                    except:
                        continue
            
            # Try to find direct download link patterns
            dlink_patterns = [
                r'"dlink"\s*:\s*"([^"]+)"',
                r'dlink:\s*"([^"]+)"',
                r'download_url\s*:\s*"([^"]+)"'
            ]
            
            for pattern in dlink_patterns:
                match = re.search(pattern, html)
                if match:
                    dlink = match.group(1).replace('\\/', '/')
                    print(f"[DEBUG] Found dlink pattern: {dlink[:50]}...")
                    
                    # Try to find filename
                    filename_match = re.search(r'"server_filename"\s*:\s*"([^"]+)"', html)
                    filename = filename_match.group(1) if filename_match else "video"
                    
                    return dlink, filename, None
            
            return None, None, "Could not extract download link from page. The link may require a password or the cookie may be expired."
            
        except Exception as e:
            print(f"[DEBUG] HTML extraction error: {e}")
            return None, None, f"HTML extraction failed: {str(e)}"


# Testing function
if __name__ == "__main__":
    # Example usage
    ndus = "your_ndus_cookie_here"
    extractor = TeraBoxExtractor(ndus)
    
    test_link = "https://www.terabox.com/s/1xxxxxx"
    direct_url, filename, error = extractor.get_direct_link(test_link)
    
    if error:
        print(f"Error: {error}")
    else:
        print(f"Filename: {filename}")
        print(f"Direct URL: {direct_url}")
