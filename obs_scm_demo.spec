#
# spec file for package obs_scm_demo
#
# Copyright (c) 2023 SUSE LLC
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via https://bugs.opensuse.org/
#

Name:           obs_scm_demo
Summary:        A demo of OBS_SCM
Version:        0
Release:        0
License:        BSD-3-Clause
URL:            https://github.com/smithfarm/obs_scm_demo
Source0:        _service
BuildArch:      noarch

%description
All you ever wanted to know about OBS_SCM, but were afraid to ask.

%prep
%setup -q -n %_sourcedir/%name-%version -T -D

%build

%install
install -D -m 0755 obs_scm_demo %{buildroot}%{_bindir}/obs_scm_demo
install -D -m 0644 LICENSE %{buildroot}%{_datadir}/%{name}/LICENSE
install -D -m 0644 README.md %{buildroot}%{_datadir}/%{name}/README.md

%files
%dir %{_datadir}/%{name}
%license %{_datadir}/%{name}/LICENSE
%doc %{_datadir}/%{name}/README.md
%{_bindir}/obs_scm_demo

%changelog
