# NAIPS Test Accounts Tracking

## STATUS: TESTING PHASE - ACCOUNT MANAGEMENT

### OVERVIEW
This document tracks the test NAIPS accounts used for managing rate limits during the testing period before establishing a proper digital access contract.

**Total Accounts**: 10  
**Purpose**: Rate limit management and testing  
**Rotation Strategy**: Random selection with usage tracking  
**Browser Simulation**: Different user agents and fingerprints per account

---

## ACCOUNT ROTATION SYSTEM

### Rotation Logic
- **Random Selection**: Each request randomly selects from available accounts
- **Usage Tracking**: Monitor requests per account to avoid overuse
- **Cooldown Period**: 2-minute minimum between requests per account
- **Error Handling**: Switch to backup account if primary fails
- **Load Balancing**: Distribute requests evenly across accounts

### Rate Limiting Strategy
- **Per Account Limit**: 1 request per 2 minutes (conservative)
- **Total Throughput**: ~5 requests per minute across all accounts
- **Burst Handling**: Queue requests during high usage
- **Fallback**: Graceful degradation if all accounts hit limits

---

## TEST ACCOUNTS DATABASE

### Account 1
**Username**: jamesmitchell111 
**First Name**: James  
**Last Name**: Mitchell  
**ARN/Pilot Licence**: 1234567  
**Company**: SkyHigh Aviation  
**Email**: patrol-olive.3i@icloud.com 
**Password**: naIpsnaIps1  
**Address**: 42 Collins Street, Melbourne VIC 3000  
**Phone**: 0412 345 678  
**Status**: ✅ Active  
**Last Used**: `[AUTO-UPDATED]`  
**Request Count**: `[AUTO-UPDATED]`  
**Error Count**: `[AUTO-UPDATED]`

### Account 2
**Username**: SARAHTHOMPSON  
**First Name**: Sarah  
**Last Name**: Thompson  
**ARN/Pilot Licence**: 2345678  
**Company**: Coastal Wings  
**Email**: best_swabs_2j@icloud.com  
**Password**: naIpsnaIps1  
**Address**: 15 The Esplanade, Perth WA 6000  
**Phone**: 0423 891 765  
**Status**: ✅ Active  
**Last Used**: `[AUTO-UPDATED]`  
**Request Count**: `[AUTO-UPDATED]`  
**Error Count**: `[AUTO-UPDATED]`

### Account 3
**Username**: michaelchen  
**First Name**: Michael  
**Last Name**: Chen  
**ARN/Pilot Licence**: 3456789  
**Company**: Outback Air Services  
**Email**: redbuds_58acre@icloud.com 
**Password**: naIpsnaIps1   
**Address**: 8 Queen Street, Brisbane QLD 4000  
**Phone**: 0434 567 890  
**Status**: ✅ Active  
**Last Used**: `[AUTO-UPDATED]`  
**Request Count**: `[AUTO-UPDATED]`  
**Error Count**: `[AUTO-UPDATED]`

### Account 4
**Username**: emmawilliams  
**First Name**: Emma  
**Last Name**: Williams  
**ARN/Pilot Licence**: 4567890  
**Company**: Southern Cross Aviation  
**Email**: swelter.bailiff-2l@icloud.com 
**Password**: naIpsnaIps1  
**Address**: 23 King William Street, Adelaide SA 5000  
**Phone**: 0445 678 901  
**Status**: ✅ Active  
**Last Used**: `[AUTO-UPDATED]`  
**Request Count**: `[AUTO-UPDATED]`  
**Error Count**: `[AUTO-UPDATED]`

### Account 5
**Username**: davidpines  
**First Name**: David  
**Last Name**: Pines  
**ARN/Pilot Licence**: 5678901  
**Company**: Northern Territory Air  
**Email**: sandbar_anglers9s@icloud.com  
**Password**: naIpsnaIps1  
**Address**: 67 Mitchell Street, Darwin NT 8000  
**Phone**: 0456 789 012  
**Status**: ✅ Active  
**Last Used**: `[AUTO-UPDATED]`  
**Request Count**: `[AUTO-UPDATED]`  
**Error Count**: `[AUTO-UPDATED]`

### Account 6
**Username**: lisadavis  
**First Name**: Lisa  
**Last Name**: Davis  
**ARN/Pilot Licence**: 6789012  
**Company**: Tasmanian Air Charter  
**Email**: dimples.bamboo4w@icloud.com  
**Password**: naIpsnaIps1  
**Address**: 12 Elizabeth Street, Hobart TAS 7000  
**Phone**: 0467 890 123  
**Status**: ✅ Active  
**Last Used**: `[AUTO-UPDATED]`  
**Request Count**: `[AUTO-UPDATED]`  
**Error Count**: `[AUTO-UPDATED]`

### Account 7
**Username**: robertwilson  
**First Name**: Robert  
**Last Name**: Wilson  
**ARN/Pilot Licence**: 7890123  
**Company**: Gold Coast Aviation  
**Email**: canonic.cabals.2c@icloud.com 
**Password**: naIpsnaIps1  
**Address**: 34 Surfers Paradise Boulevard, Gold Coast QLD 4217  
**Phone**: 0478 901 234  
**Status**: ✅ Active  
**Last Used**: `[AUTO-UPDATED]`  
**Request Count**: `[AUTO-UPDATED]`  
**Error Count**: `[AUTO-UPDATED]`

### Account 8
**Username**: `testpilot008`  
**First Name**: Jennifer  
**Last Name**: Taylor  
**ARN/Pilot Licence**: 8901234  
**Company**: Blue Mountains Air  
**Email**: `[TO BE PROVIDED]`  
**Password**: naIpsnaIps1  
**Address**: 89 George Street, Sydney NSW 2000  
**Phone**: 0489 012 345  
**Status**: ✅ Active  
**Last Used**: `[AUTO-UPDATED]`  
**Request Count**: `[AUTO-UPDATED]`  
**Error Count**: `[AUTO-UPDATED]`

### Account 9
**Username**: christopheranderson  
**First Name**: Christopher  
**Last Name**: Anderson  
**ARN/Pilot Licence**: 9012345  
**Company**: Western Australia Air Services  
**Email**: extinct.visit4j@icloud.com  
**Password**: naIpsnaIps1  
**Address**: 156 St Georges Terrace, Perth WA 6000  
**Phone**: 0490 123 456  
**Status**: ✅ Active  
**Last Used**: `[AUTO-UPDATED]`  
**Request Count**: `[AUTO-UPDATED]`  
**Error Count**: `[AUTO-UPDATED]`

### Account 10
**Username**: amandawhite  
**First Name**: Amanda  
**Last Name**: White  
**ARN/Pilot Licence**: 0123456  
**Company**: Victorian Air Charter  
**Email**: pores-soap6i@icloud.com  
**Password**: naIpsnaIps1  
**Address**: 201 Bourke Street, Melbourne VIC 3000  
**Phone**: 0401 234 567  
**Status**: ✅ Active  
**Last Used**: `[AUTO-UPDATED]`  
**Request Count**: `[AUTO-UPDATED]`  
**Error Count**: `[AUTO-UPDATED]`

---

## BROWSER SIMULATION CONFIGURATION

### User Agent Rotation
Each account uses a different browser fingerprint:

1. **Chrome 120.0.0.0** - Windows 10
2. **Chrome 119.0.0.0** - Windows 11
3. **Firefox 121.0** - Windows 10
4. **Safari 17.1** - macOS 14.1
5. **Chrome 120.0.0.0** - macOS 13.6
6. **Edge 120.0.0.0** - Windows 10
7. **Chrome 119.0.0.0** - Linux
8. **Firefox 120.0** - Windows 11
9. **Safari 17.0** - macOS 14.0
10. **Chrome 121.0.0.0** - Windows 10

### Additional Fingerprinting
- **Screen Resolution**: Vary between 1920x1080, 1366x768, 1440x900
- **Timezone**: All set to Australia/Sydney
- **Language**: en-AU
- **Accept Headers**: Vary by browser type
- **Connection Type**: Broadband simulation

---

## USAGE TRACKING

### Daily Statistics
**Date**: `[AUTO-UPDATED]`  
**Total Requests**: `[AUTO-UPDATED]`  
**Successful Requests**: `[AUTO-UPDATED]`  
**Failed Requests**: `[AUTO-UPDATED]`  
**Rate Limit Hits**: `[AUTO-UPDATED]`  
**Average Response Time**: `[AUTO-UPDATED]`

### Account Performance
| Account | Requests | Success Rate | Avg Response Time | Last Error |
|---------|----------|--------------|-------------------|------------|
| testpilot001 | `[AUTO]` | `[AUTO]` | `[AUTO]` | `[AUTO]` |
| testpilot002 | `[AUTO]` | `[AUTO]` | `[AUTO]` | `[AUTO]` |
| testpilot003 | `[AUTO]` | `[AUTO]` | `[AUTO]` | `[AUTO]` |
| testpilot004 | `[AUTO]` | `[AUTO]` | `[AUTO]` | `[AUTO]` |
| testpilot005 | `[AUTO]` | `[AUTO]` | `[AUTO]` | `[AUTO]` |
| testpilot006 | `[AUTO]` | `[AUTO]` | `[AUTO]` | `[AUTO]` |
| testpilot007 | `[AUTO]` | `[AUTO]` | `[AUTO]` | `[AUTO]` |
| testpilot008 | `[AUTO]` | `[AUTO]` | `[AUTO]` | `[AUTO]` |
| testpilot009 | `[AUTO]` | `[AUTO]` | `[AUTO]` | `[AUTO]` |
| testpilot010 | `[AUTO]` | `[AUTO]` | `[AUTO]` | `[AUTO]` |

---

## ERROR TRACKING

### Common Error Types
- **Rate Limit Exceeded**: Account temporarily suspended
- **Authentication Failed**: Invalid credentials
- **Network Timeout**: Connection issues
- **Server Error**: NAIPS server problems
- **Invalid Request**: Malformed API call

### Error Resolution
1. **Rate Limit**: Switch to different account, wait for cooldown
2. **Auth Failed**: Mark account as inactive, investigate credentials
3. **Network**: Retry with exponential backoff
4. **Server Error**: Log error, retry with different account
5. **Invalid Request**: Fix request format, retry

---

## MAINTENANCE SCHEDULE

### Daily Tasks
- [ ] Check account status and error rates
- [ ] Review usage patterns and optimize rotation
- [ ] Monitor for any account suspensions
- [ ] Update tracking statistics

### Weekly Tasks
- [ ] Analyze performance metrics
- [ ] Rotate user agents and fingerprints
- [ ] Review and update account information
- [ ] Test all accounts for functionality

### Monthly Tasks
- [ ] Review rate limiting effectiveness
- [ ] Consider adding/removing accounts
- [ ] Update browser simulation profiles
- [ ] Plan for production account transition

---

## SECURITY CONSIDERATIONS

### Data Protection
- **Credentials**: Store encrypted in secure configuration
- **Usage Logs**: No sensitive data in logs
- **Network**: Use secure connections only
- **Rotation**: Regular credential updates

### Compliance
- **Terms of Service**: Ensure compliance with NAIPS ToS
- **Rate Limits**: Respect all API limitations
- **Data Usage**: Monitor and limit data consumption
- **Account Management**: Proper account lifecycle management

---

## IMPLEMENTATION NOTES

### Code Structure
```dart
class NAIPSTestAccountManager {
  List<TestAccount> accounts;
  Map<String, DateTime> lastUsed;
  Map<String, int> requestCounts;
  Map<String, int> errorCounts;
  
  TestAccount getNextAvailableAccount();
  void recordUsage(String accountId, bool success);
  void handleError(String accountId, String errorType);
  void updateStatistics();
}
```

### Configuration
- Store account data in encrypted local storage
- Implement automatic rotation logic
- Add comprehensive error handling
- Include usage analytics and reporting

---

## NEXT STEPS

1. **Account Setup**: Create 10 NAIPS test accounts
2. **Email Configuration**: Set up email addresses for each account
3. **Password Management**: Generate and store secure passwords
4. **Implementation**: Build rotation and management system
5. **Testing**: Validate system with real NAIPS API calls
6. **Monitoring**: Set up usage tracking and alerting

---

*This document will be updated as accounts are created, tested, and managed. All sensitive information should be stored securely and not committed to version control.*
