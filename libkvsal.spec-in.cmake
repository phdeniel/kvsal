%define sourcename @CPACK_SOURCE_PACKAGE_FILE_NAME@
%global dev_version %{lua: extraver = string.gsub('@LIBKVSAL_EXTRA_VERSION@', '%-', '.'); print(extraver) }

Name: libkvsal 
Version: @LIBKVSAL_BASE_VERSION@
Release: 0%{dev_version}%{?dist}
Summary: Library to abstract a KVS to be used by KVSNS
License: LGPLv3 
Group: Development/Libraries
Url: http://github.com/phdeniel/libkvsal
Source: %{sourcename}.tar.gz
BuildRequires: cmake libini_config-devel
BuildRequires: gcc
Requires: libini_config
Provides: %{name} = %{version}-%{release}

# Conditionally enable KVS and object stores
#
# 1. rpmbuild accepts these options (gpfs as example):
#    --without redis

%define on_off_switch() %%{?with_%1:ON}%%{!?with_%1:OFF}

# A few explanation about %bcond_with and %bcond_without
# /!\ be careful: this syntax can be quite messy
# %bcond_with means you add a "--with" option, default = without this feature
# %bcond_without adds a"--without" so the feature is enabled by default

@BCOND_MOTR@ motr
%global use_motr %{on_off_switch motr}

@BCOND_REDIS@ redis
%global use_redis %{on_off_switch redis}

%description
The libkvsal is a library that allows of a POSIX namespace built on top of
a Key-Value Store.

%package devel
Summary: Development file for the library libkvsal
Group: Development/Libraries
Requires: %{name} = %{version}-%{release} pkgconfig
Provides: %{name}-devel = %{version}-%{release}

# REDIS
%if %{with redis}
%package redis
Summary: The REDIS based kvsal
Group: Applications/System
Requires: %{name} = %{version}-%{release} librados2
Provides: %{name}-kvsal-redis = %{version}-%{release}
Requires: redis hiredis
BuildRequires: hiredis-devel

%description redis
This package contains a library for using REDIS as a KVS for libkvsal
%endif

# MOTR
%if %{with motr}
%package motr
Summary: The MOTR based backend for libkvsal
Group: Applications/System
Requires: %{name} = %{version}-%{release} cortx-motr
Provides: %{name}-motr = %{version}-%{release}

%description motr
This package contains libraries for using CORTX-MOTR as a backend for libkvsal
%endif


%description devel
The libkvsal is a library that allows of a POSIX namespace built on top of
a Key-Value Store.
This package contains tools for libkvsal.

%prep
%setup -q -n %{sourcename}

%build
cmake . 

make %{?_smp_mflags} || make %{?_smp_mflags} || make

%install

mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_libdir}
mkdir -p %{buildroot}%{_libdir}/pkgconfig
mkdir -p %{buildroot}%{_includedir}/kvsns
mkdir -p %{buildroot}%{_sysconfdir}/kvsns.d
install -m 644 include/kvsns/kvsal.h  %{buildroot}%{_includedir}/kvsns
%if %{with redis}
install -m 644 kvsal/redis/libkvsal_redis.so %{buildroot}%{_libdir}
%endif

%if %{with motr}
install -m 644 kvsal/motr/libkvsal_motr.so %{buildroot}%{_libdir}
install -m 644 motr/libm0common.so %{buildroot}%{_libdir}
%endif

install -m 644 libkvsal.pc  %{buildroot}%{_libdir}/pkgconfig
install -m 644 kvsns.ini %{buildroot}%{_sysconfdir}/kvsns.d

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%config(noreplace) %{_sysconfdir}/kvsns.d/kvsns.ini

%files devel
%defattr(-,root,root)
%{_libdir}/pkgconfig/libkvsal.pc
%{_includedir}/kvsns/kvsal.h

%if %{with redis}
%files redis
%{_libdir}/libkvsal_redis.so*
%endif

%if %{with motr}
%files motr
%{_libdir}/libkvsal_motr.so*
%{_libdir}/libm0common.so*
%endif

%changelog
* Wed Nov  3 2021 Philippe DENIEL <philippe.deniel@cea.fr> 1.3.0
- Better layering between kvsns, kvsal aand extstore. 
