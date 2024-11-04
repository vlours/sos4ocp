# MG_CLUSTER_STATUS ChangeLog

## Version 1.x.x - Template

### Minor updates - 1.x.x

- **Additional components/features to the Main script server project.** (Placeholder for future additions)

### Release updates - 1.x.x

- **Add more test cases and reference.** (Placeholder for future additions)

--------

## Version 1.0.4

### Minor updates - 1.0.4

- None

### Release updates - 1.0.4

- (Main) Adding the option '-I', allowing pod/container review from a specific 'container ID' (truncated to 13 characters)

--------

## Version 1.0.3

### Minor updates - 1.0.3

- None

### Release updates - 1.0.3

- Add alternative PATH for the crictl outputs (inspects and logs)

--------

## Version 1.0.2

### Minor updates - 1.0.2

- None

### Release updates - 1.0.2

- 'crictl stats' is now providing the name of the container. Including this in the stat function.

--------

## Version 1.0.1

### Minor updates - 1.0.1

- None

### Release updates - 1.0.1

- Adding the POD status when displaying the POD menu.
- Sorting the POD Menu by POD status and Namespace

--------

## Version 1.0.0

### Minor updates - 1.0.0

- (Main) Allowing to display the container statistics by cpu, mem, disk or inodes with the new option '-S'
- (Global) Set the script as stable and move to release 1.X.X

### Release updates - 1.0.0

- (Main) Including the Container resources usage when displaying the container menu.
- (Main) Merging of the inspect functions.
- (Main) Adding headers to the POD and Containers details.
- (Main) Including colors to display the help in right format (and maybe future usages)
- (README) Including the new option from the help output.

--------

## Version 0.4.2

### Minor updates - 0.4.2

- None

### Release updates - 0.4.2

- (Main) Allowing to (q)uit from the POD list menu.
- (Main) Updating pagination in the menu to be similar accross the displays.
- (Main) Enforcing statement to avoid a combinaison of numbers/letters in the choices

--------

## Version 0.4.1

### Minor updates - 0.4.1

- None

### Release updates - 0.4.1

- (README) Fix a typo
- (Main) Ensure the inspect files are 'JSON DATA' when searching for the cgroup, avoiding filtering failure (Issue #9 point 2.)

--------

## Version 0.4.0

### Minor updates - 0.4.0

- (Main) Replacing the option '-n', by '-p' when querying for a POD name.
- (Main) Adding the option '-n', allowing pod/container review from a specific namespace as requested in RFE #7

### Release updates - 0.4.0

- (Main) Fixing issue with duplicate entries when the same container is listed twice in the same POD (exitec & running)
- (Main) Simplifying the parameter management, using a 'PODFILTER' variable and a 'case' statement validation.

--------

## Version 0.3.0

### Minor updates - 0.3.0

- (Main) Adding the option '-g', allowing pod/container review from a specific cgroup as requested in RFE #5

### Release updates - 0.3.0

- (Help) Reduce space when displaying the current version
- (Main) Enforcing the number of parameters.
- (Main) Redirecting some command error message to the output set in variable ${STD_ERR}
- (Various) Rewriting few messages and comments.

--------

## Version 0.2.1

### Minor updates - 0.2.1

- None

### Release updates - 0.2.1

- Update 'awk' filter based on different crictl_ps_-a output when retreiving the POD list from a container name.
- Add the version number in the help message

--------

## Version 0.2.0

### Minor updates - 0.2.0

- Allowing to retrieve the POD list from the available IDs in the list (issue #2)
- Allowing to retrieve the POD list from the specified container name (issue #3)

### Release updates - 0.2.0

- Fixing typo in help
- Updating help with the new features

--------

## Version 0.1.0

### Minor updates - 0.1.0

- Initial Version

### Release updates - 0.1.0

- None
