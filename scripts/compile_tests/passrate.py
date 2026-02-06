import argparse
from common import (
    get_excluded_testcases,
    get_passed_testcases,
    get_testcases,
    key,
    open_test_results,
)
from download_reports import download_reports


def testcases_by_time(xmls):
    """Return testcases sorted by descending execution time."""
    return sorted(get_testcases(xmls), key=lambda x: float(x.attrib["time"]), reverse=True)


def should_exclude(test_key: str) -> bool:
    """Return True if the test should be excluded from passrate calculation."""
    test_file = test_key.split("::")[0]
    if test_file == "UNKNOWN":
        return True
    return test_file.startswith(("inductor/", "export/", "dynamo/"))


def compute_pass_rate(eager_dir, dynamo_dir):
    """Compute pass rate of Dynamo tests relative to eager tests."""
    print("Parsing XML test results...")
    eager_xmls = open_test_results(eager_dir)
    dynamo_xmls = open_test_results(dynamo_dir)

    print("Computing pass rate...")
    eager_passed = get_passed_testcases(eager_xmls)
    dynamo_passed = get_passed_testcases(dynamo_xmls)

    eager_pass_keys = {key(tc) for tc in eager_passed if not should_exclude(key(tc))}
    dynamo_pass_keys = {key(tc) for tc in dynamo_passed if not should_exclude(key(tc))}

    # Remove excluded testcases
    excluded = {key(t) for t in get_excluded_testcases(dynamo_xmls)}
    eager_pass_keys -= excluded

    # Compute pass rate
    passed_in_both = eager_pass_keys & dynamo_pass_keys
    total_passed = len(passed_in_both)
    total_tests = len(eager_pass_keys)
    pass_rate = total_passed / total_tests if total_tests else 0.0

    print(f"Pass rate: {pass_rate:.2%} ({total_passed}/{total_tests})")

    # Optional debugging: find keys present in eager but missing in dynamo
    dynamo_testcases = {key(t): t for t in get_testcases(dynamo_xmls)}
    missing_keys = eager_pass_keys - set(dynamo_testcases)

    fail_keys = eager_pass_keys - passed_in_both
    return fail_keys


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="passrate",
        description="Computes the Dynamo unittest pass rate"
    )
    parser.add_argument(
        "commit",
        help="Commit SHA for which to pull CI test results."
    )
    args = parser.parse_args()

    dynamo_dir, eager_dir = download_reports(args.commit, ("dynamo311", "eager311"))
    compute_pass_rate(eager_dir, dynamo_dir)
